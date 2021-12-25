#include "llvm/Transforms/Instrumentation/PGOStat.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ProfileSummaryInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/MDBuilder.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Transforms/Instrumentation/Infer.h"

#include <map>
#include <set>
#include <vector>

namespace llvm {
// Command line option to enable/disable the stat profiler.
static cl::opt<bool>
    EnableStatProfReporter("stat-prof-reporter", cl::init(false), cl::Hidden,
                           cl::desc("Enable the stat prof reporter"));

static cl::opt<bool>
    EnableStatProfInstrument("stat-prof-instrument", cl::init(false),
                             cl::Hidden,
                             cl::desc("Enable the stat prof instrumentor"));

static cl::opt<bool>
    EnableStatProfCompare("stat-prof-compare", cl::init(false), cl::Hidden,
                          cl::desc("Compare the inferred branch weight"));

static cl::opt<bool>
    EnableStatProfNormalize("stat-prof-normalize", cl::init(false), cl::Hidden,
                            cl::desc("Normalize the branch weights"));

} // namespace llvm

// A pass that reports the function entry count based on some parameters.
namespace {

////////////////////////////////////////////////////////////////////////////////
//
//  Feature collection.
//
////////////////////////////////////////////////////////////////////////////////

using namespace llvm;
struct BlockFeatures {
  enum Features {
    num_instr,
    num_phis,
    num_calls,
    num_loads,
    num_stores,
    num_preds,
    num_succ,
    ends_with_unreachable,
    ends_with_return,
    ends_with_cond_branch,
    ends_with_branch,
    last
  };

  void clear() {
    for (int i = 0; i < last; i++)
      ff[i] = 0;
  }
  void save(std::vector<float> &fv) {
    for (int i = 0; i < last; i++) {
      fv.push_back(ff[i]);
    }
  }
  float ff[last];
};

struct BranchFeatures {
  enum Features {
    is_entry_block,
    num_blocks_in_fn,
    condition_cmp,
    condition_predicate,
    condition_in_block,
    predicate_is_eq,
    predicate_is_fp,
    predicate_is_const,
    left_self_edge,
    right_self_edge,
    left_is_backedge,
    right_is_backedge,
    right_points_to_left,
    left_points_to_right,
    loop_depth,
    is_loop_header,
    is_left_exiting,
    is_right_exiting,

    dominates_left,
    dominates_right,
    dominated_by_left,
    dominated_by_right,
    num_blocks_this_dominates,
    last
  };

  void clear() {
    current.clear();
    left.clear();
    right.clear();
    for (int i = 0; i < last; i++)
      ff[i] = 0;
  }
  void save(std::vector<float> &fv) {
    for (int i = 0; i < last; i++) {
      fv.push_back(ff[i]);
    }
    current.save(fv);
    left.save(fv);
    right.save(fv);
  }
  float ff[last];

  BlockFeatures current;
  BlockFeatures left;
  BlockFeatures right;
};

void fillBlockFeatures(BasicBlock *BB, BlockFeatures *BF) {
#define FEATURE(FN) BF->ff[BlockFeatures::FN]
  FEATURE(num_preds) += std::distance(pred_begin(BB), pred_end(BB));
  FEATURE(num_succ) += std::distance(succ_begin(BB), succ_end(BB));

  auto *T = BB->getTerminator();
  if (isa<UnreachableInst>(*T)) {
    FEATURE(ends_with_unreachable) += 1;
  }
  if (isa<ReturnInst>(*T)) {
    FEATURE(ends_with_return) += 1;
  }
  if (BranchInst *BR = dyn_cast<BranchInst>(T)) {
    FEATURE(ends_with_branch) += BR->isUnconditional();
    FEATURE(ends_with_cond_branch) += BR->isConditional();
  }

  for (auto &inst : *BB) {
    FEATURE(num_instr) += 1;
    if (isa<CallInst>(inst)) {
      FEATURE(num_calls) += 1;
    }
    if (isa<PHINode>(inst)) {
      FEATURE(num_phis) += 1;
    }
    if (isa<LoadInst>(inst)) {
      FEATURE(num_loads) += 1;
    }
    if (isa<StoreInst>(inst)) {
      FEATURE(num_stores) += 1;
    }
  }
#undef FEATURE
}

void fillFeatures(BranchInst *BR, BranchFeatures *BF, LoopInfo *LI,
                  DominatorTree *DT, std::set<BasicBlock *> &visited) {
#define FEATURE(FN) BF->ff[BranchFeatures::FN]

  BasicBlock *C = BR->getParent();
  BasicBlock *L = BR->getSuccessor(0);
  BasicBlock *R = BR->getSuccessor(1);
  BasicBlock *E = &C->getParent()->getEntryBlock();

  FEATURE(loop_depth) = LI->getLoopDepth(C);
  FEATURE(is_loop_header) = LI->isLoopHeader(C);
  FEATURE(is_left_exiting) = LI->getLoopFor(C) == LI->getLoopFor(L);
  FEATURE(is_right_exiting) = LI->getLoopFor(C) == LI->getLoopFor(R);

  FEATURE(dominates_left) = DT->dominates(C, L);
  FEATURE(dominates_right) = DT->dominates(C, R);
  FEATURE(dominated_by_left) = DT->dominates(L, C);
  FEATURE(dominated_by_right) = DT->dominates(R, C);

  FEATURE(is_entry_block) = (C == E);
  FEATURE(left_self_edge) = (C == L);
  FEATURE(right_self_edge) = (C == R);
  FEATURE(num_blocks_in_fn) = BR->getParent()->getParent()->size();

  unsigned dominates = 0;
  for (BasicBlock &BB : *C->getParent()) {
    if (DT->dominates(C, &BB)) {
      dominates += 1;
    }
  }
  FEATURE(num_blocks_this_dominates) = dominates;

  FEATURE(left_is_backedge) = visited.count(L);
  FEATURE(right_is_backedge) = visited.count(R);

  auto LSB = succ_begin(L);
  auto LSE = succ_end(L);
  auto RSB = succ_begin(R);
  auto RSE = succ_end(R);
  FEATURE(right_points_to_left) = (std::find(LSB, LSE, R) != LSE);
  FEATURE(left_points_to_right) = (std::find(RSB, RSE, L) != RSE);

  if (CmpInst *CI = dyn_cast<CmpInst>(BR->getCondition())) {
    FEATURE(condition_cmp) = 1;
    FEATURE(condition_predicate) = CI->getPredicate();
    FEATURE(condition_in_block) = CI->getParent() == C;
    FEATURE(predicate_is_eq) = CI->isEquality();
    FEATURE(predicate_is_const) = isa<Constant>(CI->getOperand(1));
  }

  fillBlockFeatures(C, &BF->current);
  fillBlockFeatures(L, &BF->left);
  fillBlockFeatures(R, &BF->right);
  visited.insert(C);
#undef FEATURE
}

////////////////////////////////////////////////////////////////////////////////
//
//  Metadata helpers
//
////////////////////////////////////////////////////////////////////////////////

// Returns an integer between zero and 100 that represents the ratio between
// left and right.
Optional<uint64_t> getBranchProb(BranchInst *BR) {
  MDNode *WeightsNode = BR->getMetadata(LLVMContext::MD_prof);
  if (!WeightsNode)
    return None;

  // Ensure there are weights for all of the successors. Note that the first
  // operand to the metadata node is a name, not a weight.
  if (WeightsNode->getNumOperands() != BR->getNumSuccessors() + 1)
    return None;

  auto &V1 = WeightsNode->getOperand(1);
  auto &V2 = WeightsNode->getOperand(2);
  ConstantInt *W1 = mdconst::dyn_extract<ConstantInt>(V1);
  ConstantInt *W2 = mdconst::dyn_extract<ConstantInt>(V2);
  if (!W1 || !W2)
    return None;

  std::pair<unsigned, unsigned> res;
  uint64_t left = W1->getZExtValue();
  uint64_t right = W2->getZExtValue();
  uint64_t total = left + right;

  if (total < 100)
    return None;

  return (100 * left) / (total);
}

// Assigns branch probabilities in the range 0..100 of the left branch.
void addBranchProb(BranchInst *BR, unsigned prob) {
  assert(prob <= 100 && "Invalid prob");
  unsigned left = prob;
  unsigned right = 100 - prob;

  auto *BranchProb =
      MDBuilder(BR->getContext()).createBranchWeights(left, right);
  BR->setMetadata(LLVMContext::MD_prof, BranchProb);
}

////////////////////////////////////////////////////////////////////////////////
//
//  A pass that saves features onto disk for offline training
//
////////////////////////////////////////////////////////////////////////////////

void readProfForFunction(Function &F, LoopInfo *LI, DominatorTree *DT,
                         std::string &out) {
  BranchFeatures BF;
  std::set<BasicBlock *> visited;
  if (F.empty())
    return;
  for (BasicBlock &BB : F) {
    BranchInst *BI = dyn_cast<BranchInst>(BB.getTerminator());
    if (!BI)
      continue;
    if (BI->isUnconditional())
      continue;

    auto BP = getBranchProb(BI);
    if (!BP.hasValue()) {
      continue;
    }

    auto ratio = BP.getValue();
    BF.clear();
    std::vector<float> fv;
    fillFeatures(BI, &BF, LI, DT, visited);
    out += std::to_string(ratio);
    out += std::string("  ");

    BF.save(fv);
    for (auto &elem : fv) {
      out += ", ";
      out += std::to_string(int(elem));
    }
    out += "\n";

    if (EnableStatProfNormalize) {
      addBranchProb(BI, ratio);
    }

    if (EnableStatProfCompare) {
      float res = infer(fv.data(), fv.size());
      if (res < 0.)
        continue;
      int res_int = (100. * res);
      llvm::outs() << "Metadata: " << ratio << " Infer: " << res_int
                   << " delta: " << (int)ratio - res_int << "\n";
    }
  }
}

////////////////////////////////////////////////////////////////////////////////
//
//  A pass that runs inference and annotates branches with probability metadata.
//
////////////////////////////////////////////////////////////////////////////////
float clamp(float val, float low, float high) {
  return std::max<float>(low, std::min<float>(val, high));
}

void addProfileForFunction(Function &F, LoopInfo *LI, DominatorTree *DT) {
  BranchFeatures BF;
  std::set<BasicBlock *> visited;
  if (F.empty())
    return;
  for (BasicBlock &BB : F) {
    BranchInst *BI = dyn_cast<BranchInst>(BB.getTerminator());
    if (!BI)
      continue;
    if (BI->isUnconditional())
      continue;

    BF.clear();
    fillFeatures(BI, &BF, LI, DT, visited);
    std::vector<float> fv;
    BF.save(fv);
    float res = infer(fv.data(), fv.size());
    if (res < 0.)
      continue;
    res = clamp(res * 100., 0., 100.);
    addBranchProb(BI, res);
  }
}

} // namespace

namespace llvm {

PreservedAnalyses PGOStatPass::run(Function &F, FunctionAnalysisManager &AM) {
  auto &LI = AM.getResult<LoopAnalysis>(F);
  auto &DT = AM.getResult<DominatorTreeAnalysis>(F);
  if (EnableStatProfReporter)
    readProfForFunction(F, &LI, &DT, buffer_);

  if (EnableStatProfInstrument)
    addProfileForFunction(F, &LI, &DT);

  return PreservedAnalyses::all();
}

} // namespace llvm

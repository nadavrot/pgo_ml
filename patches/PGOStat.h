//===- Transforms/Instrumentation/PGOState.h --------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_TRANSFORMS_INSTRUMENTATION_PGOSTATS_H
#define LLVM_TRANSFORMS_INSTRUMENTATION_PGOSTATS_H

#include "llvm/ADT/ArrayRef.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/Process.h"
#include "llvm/Support/raw_ostream.h"

#include <chrono>
#include <cstdint>
#include <string>

namespace llvm {

class Function;
class Instruction;
class Module;

class PGOStatPass : public PassInfoMixin<PGOStatPass> {
  std::string buffer_;

public:
  ~PGOStatPass() {
    std::string filename = "/tmp/pgo_stats";
    auto SE = sys::Process::GetEnv("PGO_SUFFIX");
    if (SE.hasValue()) {
      filename += ".";
      filename += SE.getValue();
    }

    std::error_code EC;
    raw_fd_ostream out(filename, EC, sys::fs::OF_Append);
    if (EC) {
      return;
    }

    auto ExFD = out.tryLockFor(std::chrono::milliseconds(250));
    if (!ExFD) {
      (void)ExFD.takeError();
      return;
    }
    out << buffer_;
  }

  PGOStatPass() {}
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM);
};

} // end namespace llvm

#endif // LLVM_TRANSFORMS_INSTRUMENTATION_PGOSTATS_H

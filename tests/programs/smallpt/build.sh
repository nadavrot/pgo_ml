export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/smallpt.profraw
export PROF_DATA=/tmp/smallpt.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="smallpt"

CXXF="-Os -fprofile-instr-generate"
CXXF2="-Os -fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

($CXX 1.cc $CXXF -o ./smallpt1)
(LLVM_PROFILE_FILE=$PROF_RAW ./smallpt1 4 && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
($CXX 1.cc $CXXF2 -o ./smallpt2)



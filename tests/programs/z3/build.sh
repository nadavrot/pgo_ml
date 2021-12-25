export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/z3.profraw
export PROF_DATA=/tmp/z3.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="z3"

CXXF="-fprofile-instr-generate"
CXXF2="-fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(mkdir -p build; cd build; cmake -G Ninja ../z3 -DCMAKE_CXX_FLAGS="$CXXF" && ninja)
(LLVM_PROFILE_FILE=$PROF_RAW ./build/z3 ./input.txt && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build; cd build; cmake -G Ninja ../z3 -DCMAKE_CXX_FLAGS="$CXXF2" && ninja)

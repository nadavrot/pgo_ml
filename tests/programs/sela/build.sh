export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/sela.profraw
export PROF_DATA=/tmp/sela.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="sela"

RL=-DCMAKE_BUILD_TYPE=Release
CXXF="-fprofile-instr-generate"
CXXF2="-fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(mkdir -p build1; cd build1; cmake -G Ninja ../sela -DCMAKE_CXX_FLAGS="$CXXF" $RL && ninja)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/selatests ./input.txt && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; cd build2; cmake -G Ninja ../sela -DCMAKE_CXX_FLAGS="$CXXF2" $RL && ninja)

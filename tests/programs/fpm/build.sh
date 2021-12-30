export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/fpm.profraw
export PROF_DATA=/tmp/fpm.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="fpm"

CXXF="-fprofile-instr-generate"
CXXF2="-fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"
RL=-DCMAKE_BUILD_TYPE=Release

(mkdir -p build1; cd build1; cmake -G Ninja ../fpm -DCMAKE_CXX_FLAGS="$CXXF" && ninja)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/fpm-test ./input.txt && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; cd build2; cmake -G Ninja ../fpm -DCMAKE_CXX_FLAGS="$CXXF2" $RL && ninja)


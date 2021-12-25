export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/hermes.profraw
export PROF_DATA=/tmp/hermes.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="hermes"

RM="-DCMAKE_BUILD_TYPE=Release"
CXXF="-fprofile-instr-generate"
CXXF2="-fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(mkdir -p build1; cd build1; cmake -G Ninja ../hermes $RM -DCMAKE_CXX_FLAGS="$CXXF" && ninja)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/bin/hermes ./richards.js && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; cd build2; cmake -G Ninja ../hermes $RM -DCMAKE_CXX_FLAGS="$CXXF2" && ninja -v)


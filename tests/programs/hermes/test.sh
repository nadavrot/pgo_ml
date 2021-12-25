export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/hermes.profraw
export PROF_DATA=/tmp/hermes.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++

RM="-DCMAKE_BUILD_TYPE=Release"
FAST="-mllvm -stat-prof-instrument"

(mkdir -p build1; cd build1; cmake -G Ninja ../hermes $RM -DCMAKE_CXX_FLAGS="$FAST" && ninja)
(mkdir -p build2; cd build2; cmake -G Ninja ../hermes $RM -DCMAKE_CXX_FLAGS=""      && ninja)
(time -p ./build1/bin/hermes ./richards.js)
(time -p ./build2/bin/hermes ./richards.js)

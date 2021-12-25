export LLVM=/opt/llvm/bin/
export CC=$LLVM/clang
export CXX=$LLVM/clang++

FAST="-mllvm -stat-prof-instrument"


RL=-DCMAKE_BUILD_TYPE=Release
(mkdir -p build1; cd build1; cmake -G Ninja ../sela -DCMAKE_CXX_FLAGS="$FAST" $RL && ninja)
(mkdir -p build2; cd build2; cmake -G Ninja ../sela -DCMAKE_CXX_FLAGS=""      $RL && ninja)

(time -p ./build1/sela -e ../oggvorbis/tune.wav 1.sela)
(time -p ./build2/sela -e ../oggvorbis/tune.wav 2.sela)


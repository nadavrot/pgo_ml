export LLVM=/opt/llvm/bin/
export CC=$LLVM/clang
export CXX=$LLVM/clang++

FAST="-mllvm -stat-prof-instrument -w"
REG="-w"
RL=-DCMAKE_BUILD_TYPE=Release

(mkdir -p build1; cd build1; cmake -G Ninja ../leveldb $RL -DCMAKE_CXX_FLAGS="$FAST" && ninja)
(mkdir -p build2; cd build2; cmake -G Ninja ../leveldb $RL -DCMAKE_CXX_FLAGS="$REG"  && ninja)
(time -p ./build1/skiplist_test 2>e1 > o1.txt)
(time -p ./build2/skiplist_test 2>e2 > o2.txt)


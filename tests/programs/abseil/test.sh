export LLVM=/opt/llvm/bin/
export CC=$LLVM/clang
export CXX=$LLVM/clang++

FAST="-mllvm -stat-prof-instrument"
RM="-DCMAKE_BUILD_TYPE=Release -DABSL_BUILD_TESTING=ON -DABSL_USE_GOOGLETEST_HEAD=ON"

(mkdir -p build1; cd build1; cmake -G Ninja ../abseil-cpp/ $RM -DCMAKE_CXX_FLAGS="$FAST" && ninja absl_btree_test)
(mkdir -p build2; cd build2; cmake -G Ninja ../abseil-cpp/ $RM -DCMAKE_CXX_FLAGS=""      && ninja absl_btree_test)

(time -p ./build1/bin/absl_btree_test > 1.txt)
(time -p ./build2/bin/absl_btree_test > 2.txt)


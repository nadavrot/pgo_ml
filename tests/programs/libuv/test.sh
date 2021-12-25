export LLVM=/opt/llvm/bin/
export CC=$LLVM/clang
export CXX=$LLVM/clang++

FAST="-mllvm -stat-prof-instrument"

(mkdir -p build1; cd build1; cmake -G Ninja ../libuv -DCMAKE_C_FLAGS="$FAST" $RL && ninja)
(mkdir -p build2; cd build2; cmake -G Ninja ../libuv -DCMAKE_C_FLAGS=""      $RL && ninja)

(time -p ./build1/uv_run_benchmarks_a async4)
(time -p ./build2/uv_run_benchmarks_a async4)



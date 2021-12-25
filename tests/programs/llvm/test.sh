export LLVM=/opt/llvm/bin/
export CC=$LLVM/clang
export CXX=$LLVM/clang++

FAST="-mllvm -stat-prof-instrument"
LF="-DLLVM_TARGETS_TO_BUILD=X86 -DCMAKE_BUILD_TYPE=Release"

(mkdir -p build1; cd build1; cmake -G Ninja ../llvm-11.0.0.src -DCMAKE_CXX_FLAGS="$FAST"  $LF && ninja opt llvm-stress llc)
(mkdir -p build2; cd build2; cmake -G Ninja ../llvm-11.0.0.src -DCMAKE_CXX_FLAGS=""       $LF && ninja opt llvm-stress llc)
echo "opt"
./build1/bin/llvm-stress -size=1000000 > program.ll
time -p ./build1/bin/opt -O3 program.ll -o /dev/null
time -p ./build2/bin/opt -O3 program.ll -o /dev/null
echo "llc"
./build1/bin/llvm-stress -size=30000 > program.ll
time -p ./build1/bin/llc -O3 program.ll -o /dev/null
time -p ./build2/bin/llc -O3 program.ll -o /dev/null


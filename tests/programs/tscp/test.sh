export LLVM=/opt/llvm/bin/
export LLVM=/opt/llvm/bin/
export CC=$LLVM/clang
export CXX=$LLVM/clang++

FAST="-Os -mllvm -stat-prof-instrument"
REG="-Os "

(cp -r TSCP/ build1; cd build1/; $CC *.c $FAST -o tscp)
(cp -r TSCP/ build2; cd build2/; $CC *.c $REG  -o tscp)
time -p ./build1/tscp <note.txt > /dev/null
time -p ./build2/tscp <note.txt > /dev/null


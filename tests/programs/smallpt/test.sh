export LLVM=/opt/llvm/bin/
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export SRC=libpng-1.6.37/

FAST="-Os -mllvm -stat-prof-instrument"
REG="-Os"

($CXX ./1.cc $FAST -o smallpt1)
($CXX ./1.cc $REG  -o smallpt2)
(time -p ./smallpt1 4)
(time -p ./smallpt2 4)

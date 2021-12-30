export LLVM=/opt/llvm/bin/
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export SRC=libpng-1.6.37/

FAST="-Os -mllvm -stat-prof-instrument"
REG="-Os"

($CXX ./1.cc $FAST -o regex1)
($CXX ./1.cc $REG  -o regex2)
(time -p ./regex1 input.txt)
(time -p ./regex2 input.txt)


export LLVM=/opt/llvm/bin/
export CC=$LLVM/clang
export CXX=$LLVM/clang++

FAST="-mllvm -stat-prof-instrument"

$LLVM/clang oggenc.c -Os -Wall -g -lm $FAST -o oggenc1
$LLVM/clang oggenc.c -Os -Wall -g -lm       -o oggenc2
cat /dev/urandom | head -c 30000000 > payload.bin
(time -p ./oggenc1 -raw -Q payload.bin)
(time -p ./oggenc2 -raw -Q payload.bin)



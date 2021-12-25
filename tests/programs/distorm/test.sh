export LLVM=/opt/llvm/bin/
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export FILES="./distorm/src/*.c ./distorm/examples/linux/main.c"
FAST="-Os -mllvm -stat-prof-instrument"
REG="-Os"

(mkdir -p build1; $CC $FAST $FILES -o build1/distorm)
(mkdir -p build2; $CC $REG  $FILES -o build2/distorm)

time -p ./build1/distorm $CC > /dev/null
time -p ./build2/distorm $CC > /dev/null

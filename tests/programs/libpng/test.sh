export LLVM=/opt/llvm/bin/
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export SRC=libpng-1.6.37/

FAST="-Os -mllvm -stat-prof-instrument"
REG="-Os"

(mkdir -p build1; cd build1; ../$SRC/configure CFLAGS="$FAST" && make -j 8)
(mkdir -p build2; cd build2; ../$SRC/configure CFLAGS="$REG"  && make -j 8)
(time -p ./build1/pngvalid)
(time -p ./build2/pngvalid)

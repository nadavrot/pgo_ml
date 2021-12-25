export LLVM=/opt/llvm/bin/
export CC=$LLVM/clang
export CXX=$LLVM/clang++
FAST="-Os -mllvm -stat-prof-instrument"
REG="-Os"

(cp -r lua-5.4.3 build1; cd build1; make clean; make -j 8 MYCFLAGS="$FAST" CC=$CC)
(cp -r lua-5.4.3 build2; cd build2; make clean; make -j 8 MYCFLAGS="$REG" CC=$CC)
time -p ./build1/src/lua sort.lua
time -p ./build2/src/lua sort.lua



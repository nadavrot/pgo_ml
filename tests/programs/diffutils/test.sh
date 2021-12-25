export LLVM=/opt/llvm/bin/
export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/bz2.profraw
export PROF_DATA=/tmp/bz2.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++

FAST="-Os -mllvm -stat-prof-instrument"
REG="-Os "

(objdump -d /bin/ar > 1.txt; objdump -d /bin/as > 2.txt)

(mkdir -p build1; cd build1; ../diffutils-3.8/configure ; make -j 8 CFLAGS="$FAST" CC=$CC)
(mkdir -p build2; cd build2; ../diffutils-3.8/configure ; make -j 8 CFLAGS="$REG"  CC=$CC)
time -p ./build1/src/diff -d 1.txt 2.txt > /dev/null 
time -p ./build2/src/diff -d 1.txt 2.txt > /dev/null 


export LLVM=/opt/llvm/bin/
export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/bz2.profraw
export PROF_DATA=/tmp/bz2.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++

FAST="-Os -mllvm -stat-prof-instrument"
REG="-Os "

(cd bzip2/; make clean; make bzip2 -j 8 CFLAGS="$FAST" CC=$CC; cp -f ./bzip2 ../bzip2.1)
(cd bzip2/; make clean; make bzip2 -j 8 CFLAGS="$REG"  CC=$CC; cp -f ./bzip2 ../bzip2.2)
time -p ./bzip2.1 $CC -c > /dev/null
time -p ./bzip2.2 $CC -c > /dev/null

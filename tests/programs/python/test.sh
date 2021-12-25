export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/python.profraw
export PROF_DATA=/tmp/python.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++

FAST="-mllvm -stat-prof-instrument"

(mkdir -p build1; cd build1; CFLAGS="$FAST" ../Python-3.4.0/configure && make -j 8)
(mkdir -p build2; cd build2;                ../Python-3.4.0/configure && make -j 8)
(time -p ./build1/python ./richards.py)
(time -p ./build2/python ./richards.py)


export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/python.profraw
export PROF_DATA=/tmp/python.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="python"

CXXF="-fprofile-instr-generate"
CXXF2="-fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(mkdir -p build1; cd build1; CFLAGS="$CXXF" LDFLAGS="$CXXF" ../Python-3.4.0/configure && make -j 8)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/python ./richards.py && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; cd build2; CFLAGS="$CXXF2"  ../Python-3.4.0/configure && make -j 8)


export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/bz2.profraw
export PROF_DATA=/tmp/bz2.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="bzip2"

CXXF="-Os -fprofile-instr-generate"
CXXF2="-Os -fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(cd bzip2/; make clean; make bzip2 -j 8 CFLAGS="$CXXF" LDFLAGS="$CXXF" CC=$CC)
(LLVM_PROFILE_FILE=$PROF_RAW ./bzip2/bzip2 $CC -c > /dev/null && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(cd bzip2/; make clean; make bzip2 -j 8 CFLAGS="$CXXF2" CC=$CC)


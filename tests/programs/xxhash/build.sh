export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/xxh.profraw
export PROF_DATA=/tmp/xxh.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="xxhash2"

CXXF="-Os -fprofile-instr-generate -fPIC"
CXXF2="-Os -fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter -fPIC"

(cd xxHash/; make clean; make -j 8 CFLAGS="$CXXF" CC=$CC)
(LLVM_PROFILE_FILE=$PROF_RAW ./xxHash/xxhsum $CC && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(cd xxHash/; make clean; make -j 8 CFLAGS="$CXXF2" CC=$CC)


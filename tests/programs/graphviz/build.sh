export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/gv.profraw
export PROF_DATA=/tmp/gv.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="gv"

PATH1=/tmp/gv/build1/
PATH2=/tmp/gv/build2/
CXXF="-fprofile-instr-generate"
CXXF2="-fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(mkdir -p build1; cd build1; ../graphviz-2.50.0/configure CFLAGS="$CXXF" LDFLAGS="$CXXF" CC=$CC PREFIX=$PATH1; make -j 8; make install)
(LLVM_PROFILE_FILE=$PROF_RAW $PATH1/bin/dot 1.gv -Tsvg -o 1.svg && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; cd build2; ../graphviz-2.50.0/configure CFLAGS="$CXXF" LDFLAGS="$CXXF" CC=$CC PREFIX=$PATH2; make -j 8)


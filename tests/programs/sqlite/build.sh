export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/sql.profraw
export PROF_DATA=/tmp/sql.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export SRC=sqlite-autoconf-3370000
export PGO_SUFFIX="sqlite3"

CXXF="-Os -fprofile-instr-generate"
CXXF2="-Os -fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(mkdir -p build1; cd build1;../$SRC/configure CFLAGS="$CXXF" LDFLAGS="$CXXF" && make -j 8)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/sqlite3 < ./bench.sql && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; cd build2;  ../$SRC/configure CFLAGS="$CXXF2" && make -j 8)

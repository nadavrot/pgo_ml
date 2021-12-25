export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/lua.profraw
export PROF_DATA=/tmp/lua.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="lua"

CXXF="-Os -fprofile-instr-generate"
CXXF2="-Os -fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(cd lua-5.4.3; make clean; make -j 8 MYCFLAGS="$CXXF" LDFLAGS="$CXXF" CC=$CC)
(LLVM_PROFILE_FILE=$PROF_RAW ./lua-5.4.3/src/lua sort.lua && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(cd lua-5.4.3; make clean; make -j 8 MYCFLAGS="$CXXF2"                CC=$CC)



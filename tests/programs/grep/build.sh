export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/grep.profraw
export PROF_DATA=/tmp/grep.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="grep"

CXXF="-Os -fprofile-instr-generate"
CXXF2="-O3 -fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(python3 ./gen.py > 1.db)

(mkdir -p build1; cd build1; ../grep-3.1/configure CFLAGS="$CXXF" LDFLAGS="$CXXF" CC=$CC; make -j 8)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/src/grep 1.db -e "xxx.*j8100" && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; cd build2; ../grep-3.1/configure CC=$CC; make -j 8 CFLAGS="$CXXF2")


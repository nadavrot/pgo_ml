export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/diff.profraw
export PROF_DATA=/tmp/diff.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="diff"

CXXF="-Os -fprofile-instr-generate"
CXXF2="-Os -fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(objdump -d /bin/ar > 1.txt; objdump -d /bin/as > 2.txt)

(mkdir -p build1; cd build1; ../diffutils-3.8/configure ; make -j 8 CFLAGS="$CXXF" LDFLAGS="$CXXF" CC=$CC)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/src/diff -d 1.txt 2.txt > /dev/null ; $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; cd build2; ../diffutils-3.8/configure ; make -j 8 CFLAGS="$CXXF2" LDFLAGS="$CXXF2" CC=$CC)

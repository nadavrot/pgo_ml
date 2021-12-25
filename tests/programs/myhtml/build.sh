export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/myhtml.profraw
export PROF_DATA=/tmp/myhtml.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="myhtml"
export MODEST_CFLAGS="-Wall"

CXXF="-Os -fprofile-instr-generate"
CXXF2="-Os -fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

cat yahoo.html > big.html
for i in {0..100}
do
  cat yahoo.html >> big.html
done

(rm -rf build1; cp -r myhtml build1; cd build1; make -j 8 CFLAGS="$CXXF" LDFLAGS="$CXXF" CC=$CC)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/bin/myhtml/html2sexpr big.html > /dev/null && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(rm -rf build2; cp -r myhtml build2; cd build2; make -j 8 CFLAGS="$CXXF2" CC=$CC)

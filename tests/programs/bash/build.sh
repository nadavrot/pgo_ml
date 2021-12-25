export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/bash.profraw
export PROF_DATA=/tmp/bash.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="bash"

CXXF="-Os -fprofile-instr-generate"
CXXF2="-Os -fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(mkdir -p build1; cd build1; ../bash-5.1/configure ; make -j 8  CFLAGS="$CXXF" LDFLAGS="$CXXF")
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/bash input.txt && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; cd build2; ../bash-5.1/configure ; make -j 8 CFLAGS="$CXXF2")


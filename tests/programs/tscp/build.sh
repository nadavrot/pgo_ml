export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/tscp.profraw
export PROF_DATA=/tmp/tscp.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="tscp"

CXXF="-Os -fprofile-instr-generate -fPIC"
CXXF2="-Os -fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(cp -r TSCP/ build1; cd build1/; $CC *.c $CXXF -o tscp)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/tscp < note.txt && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(cp -r TSCP/ build2; cd build2/; $CC *.c $CXXF2 -o tscp)

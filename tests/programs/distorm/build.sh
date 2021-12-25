export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/distorm.profraw
export PROF_DATA=/tmp/distorm.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="distorm"
export FILES="./distorm/src/*.c ./distorm/examples/linux/main.c"
CXXF="-Os -fprofile-instr-generate"
CXXF2="-Os -fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(mkdir -p build1; $CC $CXXF $FILES -o build1/distorm)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/distorm /bin/bash > /dev/null && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; $CC $CXXF2 $FILES -o build2/distorm)

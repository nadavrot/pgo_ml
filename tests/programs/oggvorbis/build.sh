export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/ogg.profraw
export PROF_DATA=/tmp/ogg.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="ogg"

CXXF="-fprofile-instr-generate"
CXXF2="-fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

$LLVM/clang oggenc.c -Os -Wall -g -lm $CXXF -o oggenc
LLVM_PROFILE_FILE=$PROF_RAW ./oggenc -Q -s 901820 tune.wav
$LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW
$LLVM/clang oggenc.c -Os -Wall -lm $CXXF2 $PROF_DATA


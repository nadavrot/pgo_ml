export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/XX.profraw
export PROF_DATA=/tmp/XX.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="llvm-bench"

CXXF="-fprofile-instr-generate"
CXXF2="-fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

for file in *.c; do
  $LLVM/clang $file -Os -Wall -g -lm $CXXF -o $file.bin
  LLVM_PROFILE_FILE=$PROF_RAW ./$file.bin
  $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW
  $LLVM/clang $file -Os -Wall -lm $CXXF2 $PROF_DATA -o $file.bin
  rm -f $file.bin $PROF_RAW $PROF_DATA
done

for file in *.cpp; do
  $LLVM/clang++ $file -Os -Wall -g -lm $CXXF -o $file.bin
  LLVM_PROFILE_FILE=$PROF_RAW ./$file.bin
  $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW
  $LLVM/clang++ $file -Os -Wall -lm $CXXF2 $PROF_DATA -o $file.bin
  rm -f $file.bin $PROF_RAW $PROF_DATA
done



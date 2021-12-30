export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/liblinear.profraw
export PROF_DATA=/tmp/liblinear.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="liblinear"

CXXF="-Os -fprofile-instr-generate"
CXXF2="-Os -fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(python3 ./gen.py > 1.txt)
(cp -r liblinear/ build1; cd build1; make CFLAGS="$CXXF" -j 10)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/train -s 4 ./1.txt && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(cp -r liblinear/ build2; cd build2; make CFLAGS="$CXXF2" -j 10)


export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/libpng.profraw
export PROF_DATA=/tmp/libpng.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export SRC=libpng-1.6.37/
export PGO_SUFFIX="libpng"

CXXF="-Os -fprofile-instr-generate"
CXXF2="-Os -fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(mkdir -p build1; cd build1;../$SRC/configure CFLAGS="$CXXF" LDFLAGS="$CXXF" && make -j 8)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/pngvalid && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; cd build2;  ../$SRC/configure CFLAGS="$CXXF2" && make -j 8)


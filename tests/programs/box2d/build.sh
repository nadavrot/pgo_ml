export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/box2d.profraw
export PROF_DATA=/tmp/box2d.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="box2d"

RF="-DBOX2D_BUILD_TESTBED=OFF -DCMAKE_BUILD_TYPE=Release"
CXXF="-fprofile-instr-generate"
CXXF2="-fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(mkdir -p build1; cd build1; cmake -G Ninja ../box2d -DCMAKE_CXX_FLAGS="$CXXF" $RF && ninja)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/bin/unit_test && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; cd build2; cmake -G Ninja ../box2d -DCMAKE_CXX_FLAGS="$CXXF2" $RF && ninja)


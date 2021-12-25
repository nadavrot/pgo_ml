export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/abseil.profraw
export PROF_DATA=/tmp/abseil.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="abseil"

CXXF="-fprofile-instr-generate"
CXXF2="-fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"
RM="-DCMAKE_BUILD_TYPE=Release -DABSL_BUILD_TESTING=ON -DABSL_USE_GOOGLETEST_HEAD=ON"

(mkdir -p build1; cd build1; cmake -G Ninja ../abseil-cpp/ $RM -DCMAKE_CXX_FLAGS="$CXXF" && ninja absl_btree_test)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/bin/absl_btree_test && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; cd build2; cmake -G Ninja ../abseil-cpp/ $RM -DCMAKE_CXX_FLAGS="$CXXF2" && ninja absl_btree_test)

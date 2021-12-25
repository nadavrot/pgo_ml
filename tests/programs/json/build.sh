export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/json.profraw
export PROF_DATA=/tmp/json.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="json"

CXXF="-fprofile-instr-generate"
CXXF2="-fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"
RM="-DCMAKE_BUILD_TYPE=Release"

(mkdir -p build1; cd build1; cmake -G Ninja ../json $RM -DCMAKE_CXX_FLAGS="$CXXF" && ninja)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/test/test-deserialization && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; cd build2; cmake -G Ninja ../json $RM -DCMAKE_CXX_FLAGS="$CXXF2" && ninja)


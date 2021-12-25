export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/leveldb.profraw
export PROF_DATA=/tmp/leveldb.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="leveldb"

RL=-DCMAKE_BUILD_TYPE=Release
CXXF="-fprofile-instr-generate -w"
CXXF2="-fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter -w"

(mkdir -p build1; cd build1; cmake -G Ninja ../leveldb $RL -DCMAKE_CXX_FLAGS="$CXXF" && ninja)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/issue178_test && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; cd build2; cmake -G Ninja ../leveldb $RL -DCMAKE_CXX_FLAGS="$CXXF2" && ninja)

export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/uv-%p.profraw
export PROF_DATA=/tmp/uv.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="uv"

CXXF="-fprofile-instr-generate"
CXXF2="-fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"
RL=-DCMAKE_BUILD_TYPE=Release

(mkdir -p build1; cd build1; cmake -G Ninja ../libuv -DCMAKE_LD_FLAGS="$CXXF" -DCMAKE_C_FLAGS="$CXXF" $RL && ninja)
(LLVM_PROFILE_FILE=$PROF_RAW ./build1/uv_run_benchmarks_a async1 &&
 LLVM_PROFILE_FILE=$PROF_RAW ./build1/uv_run_benchmarks_a ping_pongs &&
 LLVM_PROFILE_FILE=$PROF_RAW ./build1/uv_run_benchmarks_a sizes &&
 $LLVM/llvm-profdata merge -output=$PROF_DATA /tmp/uv*.profraw)
(mkdir -p build2; cd build2; cmake -G Ninja ../libuv -DCMAKE_LD_FLAGS="$CXXF2" -DCMAKE_C_FLAGS="$CXXF2" $RL  && ninja)


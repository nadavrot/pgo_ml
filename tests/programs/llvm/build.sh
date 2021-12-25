export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/llvm-%p.profraw
export PROF_DATA=/tmp/llvm.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="llvm"

CXXF="-fprofile-instr-generate"
CXXF2="-fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"
LF="-DLLVM_TARGETS_TO_BUILD=X86 -DCMAKE_BUILD_TYPE=Release"

(mkdir -p build; cd build; cmake -G Ninja ../llvm-11.0.0.src -DCMAKE_CXX_FLAGS="$CXXF"  $LF && ninja llc llvm-stress opt)
(LLVM_PROFILE_FILE=$PROF_RAW ./build/bin/llvm-stress -size=10000 > 1.ll && \
	LLVM_PROFILE_FILE=$PROF_RAW ./build/bin/llc ./1.ll &&\
	LLVM_PROFILE_FILE=$PROF_RAW ./build/bin/opt -Os ./1.ll -o 1.bc && \
	$LLVM/llvm-profdata merge -output=$PROF_DATA /tmp/llvm*.profraw)
(mkdir -p build; cd build; cmake -G Ninja ../llvm-11.0.0.src -DCMAKE_CXX_FLAGS="$CXXF2" $LF && ninja llc llvm-stress opt)




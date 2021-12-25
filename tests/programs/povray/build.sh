export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/povray.profraw
export PROF_DATA=/tmp/povray.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="pov"

CXXF="-fprofile-instr-generate"
CXXF2="-fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(cd povray/unix/; ./prebuild.sh;)
(mkdir -p build1; cd build1; ../povray/configure COMPILED_BY="X" CFLAGS="$CXXF" LDFLAGS="$CXXF"  && make -j 8)
#(LLVM_PROFILE_FILE=$PROF_RAW ./build1/ ./input.txt && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
(mkdir -p build2; cd build2; ../povray/configure COMPILED_BY="X" CFLAGS="$CXXF2" LDFLAGS="$CXXF2"  && make -j 8)

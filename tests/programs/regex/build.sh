export LLVM=/opt/llvm/bin/
export PROF_RAW=/tmp/regex.profraw
export PROF_DATA=/tmp/regex.profdata
export CC=$LLVM/clang
export CXX=$LLVM/clang++
export PGO_SUFFIX="regex"

CXXF="-Os -fprofile-instr-generate"
CXXF2="-Os -fprofile-instr-use=$PROF_DATA -mllvm -stat-prof-reporter"

(python3 ./gen.py > input.txt)

($CXX 1.cc $CXXF -o ./regex1)
(LLVM_PROFILE_FILE=$PROF_RAW ./regex1 input.txt && $LLVM/llvm-profdata merge -output=$PROF_DATA $PROF_RAW)
($CXX 1.cc $CXXF2 -o ./regex2)



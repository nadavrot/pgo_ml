# Profile generation run:
CCC="-DCMAKE_C_COMPILER=/opt/llvm/bin/clang"
BENCH="-DTEST_SUITE_BENCHMARKING_ONLY=ON -DCMAKE_C_FLAGS_OPTIMIZE=-Os"
TS="~/llvm-test-suite"

(mkdir -p ~/test-suite-build1; cd ~/test-suite-build1 &&
 cmake $CCC $TS -G Ninja $BENCH &&
 ninja -k 1000; lit -j 1 . -o ~/before.json)

(mkdir -p ~/test-suite-build2; cd ~/test-suite-build2 &&
 cmake $CCC $TS -G Ninja $BENCH -DCMAKE_C_FLAGS="-mllvm -stat-prof-instrument"  &&
 ninja -k 1000; lit -j 1 . -o ~/after.json)

# Profile generation run:
CCC="-DCMAKE_C_COMPILER=/opt/llvm/bin/clang"
TRAIN="-DTEST_SUITE_PROFILE_GENERATE=ON -DTEST_SUITE_RUN_TYPE=train -DTEST_SUITE_BENCHMARKING_ONLY=ON"
USE="-DTEST_SUITE_PROFILE_GENERATE=OFF -DTEST_SUITE_PROFILE_USE=ON -DTEST_SUITE_BENCHMARKING_ONLY=ON"
TS="~/llvm-test-suite"

(mkdir -p ~/test-suite-build &&
 cd ~/test-suite-build &&
 cmake $CCC $TS -G Ninja $TRAIN &&
 ninja -k 100; lit .)

(cd ~/test-suite-build &&
 cmake $CCC $TS -G Ninja $USE -DCMAKE_C_FLAGS="-mllvm -stat-prof-reporter" &&
 ninja -k 100; lit . -o results.json)

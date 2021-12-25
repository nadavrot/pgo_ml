# Profile Guided Optimization without Profiles: A Machine Learning Approach.

This repository contains the source code for the paper "Profile Guided
Optimization without Profiles: A Machine Learning Approach" by Nadav Rotem and Chris Cummins.
Paper link XXXX.

## Getting Started

This repository is small because we don't save a whole copy of LLVM. Instead
this repository contains a patch against LLVM-13. The scripts in the docker image
apply the patch and create a working toolchain inside the docker image. If you
are just interested in reading the code then the interesting bits are in the two
directories ./patches/ (LLVM pass) and ./offline/ (ML trainer). You can use the
docker image to compile the clang-13 toolchain.


```
$ ./utils/create_image.sh

$ ./utils/run_image.sh
```

Notice that downloading the LLVM test suite and building clang can take around
30 minutes. At the end of the process you should be able to use clang with the
new flag "-Os -mllvm -stat-prof-instrument".

```
$ /opt/llvm/bin/clang -Os -mllvm -stat-prof-instrument 1.c -emit-llvm -S -o -
```

## Code Example:

Let's take a look at a quick example. If you compile the C function below with
the flag that enables the new pass then it would insert branch weight metadata
on the branches in the code. The LLVM-IR code below demonstrates that this time
the pass made a reasonable decision to mark the backward branch as very likely
and the error check as unlikely.  Notice that the IR code below was manualy
edited to remove unrelated metadata to make the IR more readable.

```
int foo(int *A, int len) {

  if (A == 0) return 0;

  for (int i = 0; i < len; i+=2) {
    A[i] = 3;
  }

  return 1;
}

```


```
define i32 @foo(i32* %0, i32 %1) {
  %3 = icmp eq i32* %0, null
  br i1 %3, label %13, label %4, !prof !0

4:
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %6, label %13, !prof !1

6:
  %7 = zext i32 %1 to i64
  br label %8

8:
  %9 = phi i64 [ 0, %6 ], [ %11, %8 ]
  %10 = getelementptr inbounds i32, i32* %0, i64 %9
  store i32 3, i32* %10, align 4
  %11 = add nuw nsw i64 %9, 2
  %12 = icmp ult i64 %11, %7
  br i1 %12, label %8, label %13, !prof !1

13:
  %14 = phi i32 [ 0, %2 ], [ 1, %4 ], [ 1, %8 ]
  ret i32 %14
}

!0 = !{!"branch_weights", i32 0, i32 100}
!1 = !{!"branch_weights", i32 100, i32 0}
```

## Training new models

If you want to try to create a new machine learning model you can train it
yourself.  Make sure to unzip the compressed csv test files in the directory
./profiles/ before you train them. After you train the model and create a new
predictor you will need to replace the 'predict.h' file in the /patch/
directory.

```
$./offline/xg.py profiles/all.100+.small -m "training a new model" -o predict.h

```

To collect new csv files to train the model you can use the scripts in the
directory /tests. The new csv files will be placed under /tmp/pgo_stats.XXX.

To copy files outside of docker container type:

```
$ docker ps

$ docker cp XXXXXX:/tmp/pgo_stats 1.csv

```

The model file that's included with this repo is trained with the small database
and a new experimental mode that uses only 3 branch labels (0%, 50%, 100%). This
is the outcome of the benchmark on a few programs:

|Name|Ratio|Without|With|
|----|-----|-------|----|
|diff|X 0.91|5.75|6.32|
|z3|X 0.97|2.95|3.03|
|libpng|X 0.98|7.64|7.83|
|oggvorbis|X 0.98|3.12|3.17|
|llvm-llc|X 0.99|13.02|13.21|
|bzip2|X 0.99|14.74|14.85|
|llvm-opt|X 1.00|4.9|4.9|
|sela|X 1.00|0.17|0.17|
|distorm3|X 1.01|20.04|19.93|
|abseil|X 1.01|5.67|5.62|
|lua|X 1.03|7.88|7.68|
|python|X 1.05|12.4|11.85|
|hermes|X 1.09|5.29|4.87|
|sqlite3|X 1.09|8.01|7.35|
|leveldb|X 1.12|0.95|0.85|

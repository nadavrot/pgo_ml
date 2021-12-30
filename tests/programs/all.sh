LST="fmt  hermes  llvm  llvm-benchmarks  lua  oggvorbis  python z3 sqlite bzip2 json abseil distorm bash diffutils libpng sela myhtml libuv box2d leveldb tscp smallpt regex xxhash fpm liblinear"

for TT in $LST; do
  (cd $TT; ./build.sh)
done


LST="fmt hermes llvm llvm-benchmarks lua oggvorbis python z3 sqlite bzip2 json abseil distorm bash diffutils libpng sela libuv myhtml box2d leveldb"

for TT in $LST; do
  echo "Downloading " $TT
  (cd $TT; ./download.sh)
  echo DONE
done


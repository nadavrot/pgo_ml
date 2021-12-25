LST="hermes lua abseil python sqlite bzip2 llvm z3 distorm diffutils libpng"


for TT in $LST; do
  echo "Testing " $TT
  (cd $TT; ./test.sh)
  echo DONE
done


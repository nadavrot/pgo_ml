#include <assert.h>
#include <stdint.h>

namespace {

#include "predict.h"

float infer(float *input, uint32_t len) {
  int res = predict(input, len);
  // Convert the labels to branch probabilities:
  if (res < 0) {
    return -1.;
  }
  switch (res) {
  case 0:
    return 0;
  case 1:
    return 0.5;
  case 2:
    return 1.0;
  default:
    return -1;
  }
}

} // namespace

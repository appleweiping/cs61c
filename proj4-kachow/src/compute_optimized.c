#include <omp.h>
#include <x86intrin.h>

#include "compute.h"

// Horizontally sum the 8 int32 lanes of a 256-bit vector.
static inline int32_t hsum_epi32(__m256i v) {
  __m128i lo = _mm256_castsi256_si128(v);
  __m128i hi = _mm256_extracti128_si256(v, 1);
  __m128i sum128 = _mm_add_epi32(lo, hi);        // 4 partial sums
  __m128i shuf = _mm_shuffle_epi32(sum128, _MM_SHUFFLE(1, 0, 3, 2));
  sum128 = _mm_add_epi32(sum128, shuf);          // 2 partial sums
  shuf = _mm_shuffle_epi32(sum128, _MM_SHUFFLE(2, 3, 0, 1));
  sum128 = _mm_add_epi32(sum128, shuf);          // 1 total
  return _mm_cvtsi128_si32(sum128);
}

// Optimized convolution: AVX2 (8-wide int32) inner product + OpenMP over rows.
//
// Same semantics as the naive version. We pre-flip the kernel B once so the
// inner loop is a straight element-wise multiply-accumulate, which vectorizes
// cleanly with _mm256_mullo_epi32 + _mm256_add_epi32.
int convolve(matrix_t *a_matrix, matrix_t *b_matrix, matrix_t **output_matrix) {
  uint32_t a_rows = a_matrix->rows;
  uint32_t a_cols = a_matrix->cols;
  uint32_t b_rows = b_matrix->rows;
  uint32_t b_cols = b_matrix->cols;

  uint32_t out_rows = a_rows - b_rows + 1;
  uint32_t out_cols = a_cols - b_cols + 1;

  matrix_t *out = malloc(sizeof(matrix_t));
  if (out == NULL) {
    return -1;
  }
  out->rows = out_rows;
  out->cols = out_cols;
  out->data = malloc(sizeof(int32_t) * (size_t)out_rows * out_cols);
  if (out->data == NULL) {
    free(out);
    return -1;
  }

  const int32_t *a = a_matrix->data;
  const int32_t *b = b_matrix->data;

  // Pre-flip the kernel: bflip[di*b_cols + dj] = B[(b_rows-1-di)*b_cols + (b_cols-1-dj)].
  int32_t *bflip = malloc(sizeof(int32_t) * (size_t)b_rows * b_cols);
  if (bflip == NULL) {
    free(out->data);
    free(out);
    return -1;
  }
  for (uint32_t di = 0; di < b_rows; di++) {
    for (uint32_t dj = 0; dj < b_cols; dj++) {
      bflip[di * b_cols + dj] = b[(b_rows - 1 - di) * b_cols + (b_cols - 1 - dj)];
    }
  }

  uint32_t simd_end = b_cols - (b_cols % 8);  // largest multiple of 8 <= b_cols

#pragma omp parallel for schedule(dynamic) collapse(2)
  for (uint32_t i = 0; i < out_rows; i++) {
    for (uint32_t j = 0; j < out_cols; j++) {
      __m256i acc = _mm256_setzero_si256();
      int32_t tail = 0;
      for (uint32_t di = 0; di < b_rows; di++) {
        const int32_t *a_row = a + (size_t)(i + di) * a_cols + j;
        const int32_t *b_row = bflip + (size_t)di * b_cols;
        uint32_t dj = 0;
        for (; dj < simd_end; dj += 8) {
          __m256i av = _mm256_loadu_si256((const __m256i *)(a_row + dj));
          __m256i bv = _mm256_loadu_si256((const __m256i *)(b_row + dj));
          __m256i prod = _mm256_mullo_epi32(av, bv);
          acc = _mm256_add_epi32(acc, prod);
        }
        // Handle the columns that don't fill a full 8-wide vector.
        for (; dj < b_cols; dj++) {
          tail += a_row[dj] * b_row[dj];
        }
      }
      out->data[(size_t)i * out_cols + j] = hsum_epi32(acc) + tail;
    }
  }

  free(bflip);
  *output_matrix = out;
  return 0;
}

// Executes a task
int execute_task(task_t *task) {
  matrix_t *a_matrix, *b_matrix, *output_matrix;

  char *a_matrix_path = get_a_matrix_path(task);
  if (read_matrix(a_matrix_path, &a_matrix)) {
    printf("Error reading matrix from %s\n", a_matrix_path);
    return -1;
  }
  free(a_matrix_path);

  char *b_matrix_path = get_b_matrix_path(task);
  if (read_matrix(b_matrix_path, &b_matrix)) {
    printf("Error reading matrix from %s\n", b_matrix_path);
    return -1;
  }
  free(b_matrix_path);

  if (convolve(a_matrix, b_matrix, &output_matrix)) {
    printf("convolve returned a non-zero integer\n");
    return -1;
  }

  char *output_matrix_path = get_output_matrix_path(task);
  if (write_matrix(output_matrix_path, output_matrix)) {
    printf("Error writing matrix to %s\n", output_matrix_path);
    return -1;
  }
  free(output_matrix_path);

  free(a_matrix->data);
  free(b_matrix->data);
  free(output_matrix->data);
  free(a_matrix);
  free(b_matrix);
  free(output_matrix);
  return 0;
}

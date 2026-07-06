#include "compute.h"

// Computes the convolution of two matrices.
//
// CS61C convolution semantics:
//   - Matrix B (the kernel) is flipped 180 degrees (reversed in both dims).
//   - The flipped kernel slides over matrix A only where it fully overlaps
//     (valid convolution, no padding).
//   - Output dimensions are:
//        out_rows = a_rows - b_rows + 1
//        out_cols = a_cols - b_cols + 1
//   - out[i][j] = sum over (di,dj) of A[i+di][j+dj] * Bflip[di][dj]
//     where Bflip[di][dj] = B[b_rows-1-di][b_cols-1-dj].
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
  out->data = malloc(sizeof(int32_t) * out_rows * out_cols);
  if (out->data == NULL) {
    free(out);
    return -1;
  }

  const int32_t *a = a_matrix->data;
  const int32_t *b = b_matrix->data;

  for (uint32_t i = 0; i < out_rows; i++) {
    for (uint32_t j = 0; j < out_cols; j++) {
      int32_t sum = 0;
      for (uint32_t di = 0; di < b_rows; di++) {
        for (uint32_t dj = 0; dj < b_cols; dj++) {
          int32_t a_val = a[(i + di) * a_cols + (j + dj)];
          // Flip the kernel 180 degrees.
          int32_t b_val = b[(b_rows - 1 - di) * b_cols + (b_cols - 1 - dj)];
          sum += a_val * b_val;
        }
      }
      out->data[i * out_cols + j] = sum;
    }
  }

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

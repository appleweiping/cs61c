.globl matmul

.text
# =======================================================
# FUNCTION: Matrix Multiplication of 2 integer matrices
#   d = matmul(m0, m1)
# Arguments:
#   a0 (int*)  is the pointer to the start of m0
#   a1 (int)   is the # of rows (height) of m0
#   a2 (int)   is the # of columns (width) of m0
#   a3 (int*)  is the pointer to the start of m1
#   a4 (int)   is the # of rows (height) of m1
#   a5 (int)   is the # of columns (width) of m1
#   a6 (int*)  is the pointer to the the start of d
# Returns:
#   None (void), sets d = matmul(m0, m1)
# Exceptions:
#   Make sure to check in top to bottom order!
#   - If the dimensions of m0 do not make sense,
#     this function terminates the program with exit code 38
#   - If the dimensions of m1 do not make sense,
#     this function terminates the program with exit code 38
#   - If the dimensions of m0 and m1 don't match,
#     this function terminates the program with exit code 38
# =======================================================
matmul:

    # Error checks
    li t0, 1
    blt a1, t0, error       # m0 rows < 1 -> invalid
    blt a2, t0, error       # m0 cols < 1 -> invalid
    blt a4, t0, error       # m1 rows < 1 -> invalid
    blt a5, t0, error       # m1 cols < 1 -> invalid
    bne a2, a4, error       # m0 cols must equal m1 rows

    # Prologue
    addi sp, sp, -36
    sw ra, 0(sp)
    sw s0, 4(sp)            # s0 = pointer to m0
    sw s1, 8(sp)            # s1 = rows of m0 (output rows)
    sw s2, 12(sp)           # s2 = cols of m0 (== rows of m1, dot length)
    sw s3, 16(sp)           # s3 = pointer to m1
    sw s4, 20(sp)           # s4 = cols of m1 (output cols)
    sw s5, 24(sp)           # s5 = pointer to output d
    sw s6, 28(sp)           # s6 = outer loop index (row of m0)
    sw s7, 32(sp)           # s7 = inner loop index (col of m1)

    mv s0, a0
    mv s1, a1
    mv s2, a2
    mv s3, a3
    mv s4, a5
    mv s5, a6
    li s6, 0               # outer loop: i over m0 rows

outer_loop_start:
    bge s6, s1, outer_loop_end

    li s7, 0              # inner loop: j over m1 cols

inner_loop_start:
    bge s7, s4, inner_loop_end

    # Set up the dot product of m0 row i and m1 column j.
    # arr0 = &m0[i * cols0]; stride0 = 1
    mul t0, s6, s2         # t0 = i * cols0
    slli t0, t0, 2         # * 4 bytes
    add a0, s0, t0         # a0 = pointer to start of m0 row i

    # arr1 = &m1[j]; stride1 = cols_of_m1 (elements)
    slli t1, s7, 2         # t1 = j * 4
    add a1, s3, t1         # a1 = pointer to m1[0][j]

    mv a2, s2              # number of elements = cols0 (== rows of m1)
    li a3, 1               # stride of m0 row = 1
    mv a4, s4              # stride of m1 column = cols of m1

    jal ra, dot            # a0 = dot product

    # Store result into d[i * cols1 + j]
    mul t0, s6, s4         # t0 = i * cols1
    add t0, t0, s7         # + j
    slli t0, t0, 2         # * 4 bytes
    add t0, s5, t0         # &d[i][j]
    sw a0, 0(t0)

    addi s7, s7, 1         # j++
    j inner_loop_start

inner_loop_end:
    addi s6, s6, 1         # i++
    j outer_loop_start

outer_loop_end:
    # Epilogue
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    lw s7, 32(sp)
    addi sp, sp, 36

    jr ra

error:
    li a0, 38
    j exit

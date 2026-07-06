.globl classify

.text
# =====================================
# COMMAND LINE ARGUMENTS
# =====================================
# Args:
#   a0 (int)        argc
#   a1 (char**)     argv
#   a1[1] (char*)   pointer to the filepath string of m0
#   a1[2] (char*)   pointer to the filepath string of m1
#   a1[3] (char*)   pointer to the filepath string of input matrix
#   a1[4] (char*)   pointer to the filepath string of output file
#   a2 (int)        silent mode, if this is 1, you should not print
#                   anything. Otherwise, you should print the
#                   classification and a newline.
# Returns:
#   a0 (int)        Classification
# Exceptions:
#   - If there are an incorrect number of command line args,
#     this function terminates the program with exit code 31
#   - If malloc fails, this function terminates the program with exit code 26
#
# Usage:
#   main.s <M0_PATH> <M1_PATH> <INPUT_PATH> <OUTPUT_PATH>
classify:
    # There must be exactly 5 command-line arguments (program + 4 paths).
    li t0, 5
    bne a0, t0, args_error

    # Prologue: allocate stack space for callee-saved registers and the six
    # dimension slots (rows/cols of m0, m1, input).
    addi sp, sp, -48
    sw ra, 0(sp)
    sw s0, 4(sp)            # s0 = argv
    sw s1, 8(sp)            # s1 = silent flag
    sw s2, 12(sp)           # s2 = m0 matrix pointer
    sw s3, 16(sp)           # s3 = m1 matrix pointer
    sw s4, 20(sp)           # s4 = input matrix pointer
    sw s5, 24(sp)           # s5 = h  = relu(m0 * input) pointer
    sw s6, 28(sp)           # s6 = o  = m1 * h pointer
    sw s7, 32(sp)           # s7 = classification result (argmax)
    # 36..44 used as scratch dimension storage (12 ints won't fit; use heap-free
    # local ints on the stack below via dedicated slots).
    sw s8, 36(sp)           # s8 = base pointer to the dimension scratch area
    sw s9, 40(sp)
    sw s10, 44(sp)

    mv s0, a1
    mv s1, a2

    # Reserve 24 bytes on the stack for six ints:
    #   [0] m0_rows [4] m0_cols [8] m1_rows [12] m1_cols [16] in_rows [20] in_cols
    addi sp, sp, -24
    mv s8, sp

    # ---- Read pretrained m0 ----
    lw a0, 4(s0)            # argv[1] = m0 path
    addi a1, s8, 0          # &m0_rows
    addi a2, s8, 4          # &m0_cols
    jal ra, read_matrix
    mv s2, a0

    # ---- Read pretrained m1 ----
    lw a0, 8(s0)            # argv[2] = m1 path
    addi a1, s8, 8          # &m1_rows
    addi a2, s8, 12         # &m1_cols
    jal ra, read_matrix
    mv s3, a0

    # ---- Read input matrix ----
    lw a0, 12(s0)           # argv[3] = input path
    addi a1, s8, 16         # &in_rows
    addi a2, s8, 20         # &in_cols
    jal ra, read_matrix
    mv s4, a0

    # ---- Compute h = matmul(m0, input) ----
    # h has dimensions (m0_rows x in_cols).
    lw t0, 0(s8)            # m0_rows
    lw t1, 20(s8)           # in_cols
    mul t2, t0, t1          # element count of h
    slli a0, t2, 2          # bytes = elements * 4
    jal ra, malloc
    beq a0, zero, malloc_error
    mv s5, a0               # s5 = h

    lw a1, 0(s8)            # m0_rows
    lw a2, 4(s8)            # m0_cols
    mv a3, s4               # input pointer
    lw a4, 16(s8)           # in_rows
    lw a5, 20(s8)           # in_cols
    mv a6, s5               # output h
    mv a0, s2               # m0 pointer
    jal ra, matmul

    # ---- Compute h = relu(h) (in place) ----
    mv a0, s5               # h pointer
    lw t0, 0(s8)            # m0_rows
    lw t1, 20(s8)           # in_cols
    mul a1, t0, t1          # number of elements in h
    jal ra, relu

    # ---- Compute o = matmul(m1, h) ----
    # o has dimensions (m1_rows x in_cols).
    lw t0, 8(s8)            # m1_rows
    lw t1, 20(s8)           # in_cols
    mul t2, t0, t1          # element count of o
    slli a0, t2, 2          # bytes
    jal ra, malloc
    beq a0, zero, malloc_error
    mv s6, a0               # s6 = o

    lw a1, 8(s8)            # m1_rows
    lw a2, 12(s8)           # m1_cols
    mv a3, s5               # h pointer
    lw a4, 0(s8)            # h rows = m0_rows
    lw a5, 20(s8)           # h cols = in_cols
    mv a6, s6               # output o
    mv a0, s3               # m1 pointer
    jal ra, matmul

    # ---- Write output matrix o ----
    lw a0, 16(s0)           # argv[4] = output path
    mv a1, s6               # o pointer
    lw a2, 8(s8)            # m1_rows
    lw a3, 20(s8)           # in_cols
    jal ra, write_matrix

    # ---- Compute and return argmax(o) ----
    mv a0, s6               # o pointer
    lw t0, 8(s8)            # m1_rows
    lw t1, 20(s8)           # in_cols
    mul a1, t0, t1          # number of elements in o
    jal ra, argmax
    mv s7, a0               # save classification

    # ---- If enabled, print argmax(o) and a newline ----
    bne s1, zero, skip_print   # silent mode -> do not print
    mv a0, s7
    jal ra, print_int
    li a0, '\n'
    jal ra, print_char

skip_print:
    # Free the three matrices and two intermediate results.
    mv a0, s2
    jal ra, free
    mv a0, s3
    jal ra, free
    mv a0, s4
    jal ra, free
    mv a0, s5
    jal ra, free
    mv a0, s6
    jal ra, free

    mv a0, s7               # return the classification

    # Restore the dimension scratch area.
    addi sp, sp, 24

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
    lw s8, 36(sp)
    lw s9, 40(sp)
    lw s10, 44(sp)
    addi sp, sp, 48

    jr ra

args_error:
    li a0, 31
    j exit

malloc_error:
    li a0, 26
    j exit

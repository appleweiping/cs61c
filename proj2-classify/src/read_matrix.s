.globl read_matrix

.text
# ==============================================================================
# FUNCTION: Allocates memory and reads in a binary file as a matrix of integers
#
# FILE FORMAT:
#   The first 8 bytes are two 4 byte ints representing the # of rows and columns
#   in the matrix. Every 4 bytes afterwards is an element of the matrix in
#   row-major order.
# Arguments:
#   a0 (char*) is the pointer to string representing the filename
#   a1 (int*)  is a pointer to an integer, we will set it to the number of rows
#   a2 (int*)  is a pointer to an integer, we will set it to the number of columns
# Returns:
#   a0 (int*)  is the pointer to the matrix in memory
# Exceptions:
#   - If malloc returns an error,
#     this function terminates the program with error code 26
#   - If you receive an fopen error or eof,
#     this function terminates the program with error code 27
#   - If you receive an fclose error or eof,
#     this function terminates the program with error code 28
#   - If you receive an fread error or eof,
#     this function terminates the program with error code 29
# ==============================================================================
read_matrix:

    # Prologue
    addi sp, sp, -28
    sw ra, 0(sp)
    sw s0, 4(sp)           # s0 = filename pointer
    sw s1, 8(sp)           # s1 = pointer to rows out
    sw s2, 12(sp)          # s2 = pointer to cols out
    sw s3, 16(sp)          # s3 = file descriptor
    sw s4, 20(sp)          # s4 = pointer to allocated matrix
    sw s5, 24(sp)          # s5 = number of matrix bytes to read

    mv s0, a0
    mv s1, a1
    mv s2, a2

    # fopen(filename, 0)  -- read mode
    mv a0, s0
    li a1, 0
    jal ra, fopen
    li t0, -1
    beq a0, t0, fopen_error     # fopen returns -1 on failure
    mv s3, a0                   # save file descriptor

    # fread the two header ints (rows, cols) = 8 bytes into the rows/cols pointers.
    # Read rows into *s1.
    mv a0, s3
    mv a1, s1
    li a2, 4
    jal ra, fread
    li t0, 4
    bne a0, t0, fread_error     # must read exactly 4 bytes

    # Read cols into *s2.
    mv a0, s3
    mv a1, s2
    li a2, 4
    jal ra, fread
    li t0, 4
    bne a0, t0, fread_error

    # Compute number of elements = rows * cols, and byte size = elements * 4.
    lw t1, 0(s1)                # rows
    lw t2, 0(s2)                # cols
    mul t3, t1, t2              # elements
    slli s5, t3, 2             # bytes = elements * 4

    # malloc(bytes) for the matrix data.
    mv a0, s5
    jal ra, malloc
    beq a0, zero, malloc_error  # malloc returns 0 on failure
    mv s4, a0                   # save matrix pointer

    # fread the matrix data (s5 bytes) into the allocated buffer.
    mv a0, s3
    mv a1, s4
    mv a2, s5
    jal ra, fread
    bne a0, s5, fread_error     # must read exactly s5 bytes

    # fclose the file.
    mv a0, s3
    jal ra, fclose
    bne a0, zero, fclose_error  # fclose returns 0 on success

    mv a0, s4                   # return pointer to the matrix

    # Epilogue
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    addi sp, sp, 28

    jr ra

malloc_error:
    li a0, 26
    j exit

fopen_error:
    li a0, 27
    j exit

fclose_error:
    li a0, 28
    j exit

fread_error:
    li a0, 29
    j exit

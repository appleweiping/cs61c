.globl write_matrix

.text
# ==============================================================================
# FUNCTION: Writes a matrix of integers into a binary file
# FILE FORMAT:
#   The first 8 bytes of the file will be two 4 byte ints representing the
#   numbers of rows and columns respectively. Every 4 bytes thereafter is an
#   element of the matrix in row-major order.
# Arguments:
#   a0 (char*) is the pointer to string representing the filename
#   a1 (int*)  is the pointer to the start of the matrix in memory
#   a2 (int)   is the number of rows in the matrix
#   a3 (int)   is the number of columns in the matrix
# Returns:
#   None
# Exceptions:
#   - If you receive an fopen error or eof,
#     this function terminates the program with error code 27
#   - If you receive an fclose error or eof,
#     this function terminates the program with error code 28
#   - If you receive an fwrite error or eof,
#     this function terminates the program with error code 30
# ==============================================================================
write_matrix:

    # Prologue
    addi sp, sp, -36
    sw ra, 0(sp)
    sw s0, 4(sp)           # s0 = filename pointer
    sw s1, 8(sp)           # s1 = matrix pointer
    sw s2, 12(sp)          # s2 = number of rows
    sw s3, 16(sp)          # s3 = number of columns
    sw s4, 20(sp)          # s4 = file descriptor
    sw s5, 24(sp)          # s5 = number of elements
    sw s6, 28(sp)          # s6 = scratch for the two-int header buffer address
    sw s7, 32(sp)          # (reserved / alignment)

    mv s0, a0
    mv s1, a1
    mv s2, a2
    mv s3, a3

    # fopen(filename, 1) -- write mode
    mv a0, s0
    li a1, 1
    jal ra, fopen
    li t0, -1
    beq a0, t0, fopen_error
    mv s4, a0                   # save file descriptor

    # Write the header: two ints (rows, cols). Build a small buffer on the stack.
    addi sp, sp, -8
    sw s2, 0(sp)                # rows
    sw s3, 4(sp)                # cols
    mv s6, sp                   # s6 = &header buffer

    # fwrite(fd, buffer, 2 items, 4 bytes each)
    mv a0, s4
    mv a1, s6
    li a2, 2
    li a3, 4
    jal ra, fwrite
    li t0, 2
    bne a0, t0, header_fwrite_error   # must write 2 elements

    addi sp, sp, 8              # pop the header buffer

    # Write the matrix body: rows * cols ints.
    mul s5, s2, s3              # number of elements
    mv a0, s4
    mv a1, s1
    mv a2, s5
    li a3, 4
    jal ra, fwrite
    bne a0, s5, fwrite_error    # must write s5 elements

    # fclose(fd)
    mv a0, s4
    jal ra, fclose
    bne a0, zero, fclose_error

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

# The header buffer is still on the stack when this error triggers; pop it so
# the stack pointer is balanced before exiting (exit does not return anyway,
# but keep it tidy in case of future changes).
header_fwrite_error:
    addi sp, sp, 8
    li a0, 30
    j exit

fopen_error:
    li a0, 27
    j exit

fclose_error:
    li a0, 28
    j exit

fwrite_error:
    li a0, 30
    j exit

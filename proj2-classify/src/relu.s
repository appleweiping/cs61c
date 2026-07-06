.globl relu

.text
# ==============================================================================
# FUNCTION: Performs an inplace element-wise ReLU on an array of ints
# Arguments:
#   a0 (int*) is the pointer to the array
#   a1 (int)  is the # of elements in the array
# Returns:
#   None
# Exceptions:
#   - If the length of the array is less than 1,
#     this function terminates the program with error code 36
# ==============================================================================
relu:
    # Prologue
    li t0, 1
    blt a1, t0, error   # if length < 1, terminate with error code 36

    li t1, 0            # t1 = loop index i = 0

loop_start:
    bge t1, a1, loop_end    # while (i < length)

    slli t2, t1, 2          # t2 = i * 4 (byte offset)
    add t3, a0, t2          # t3 = &array[i]
    lw t4, 0(t3)            # t4 = array[i]

    bge t4, zero, loop_continue  # if array[i] >= 0, leave it
    sw zero, 0(t3)          # else array[i] = 0

loop_continue:
    addi t1, t1, 1          # i++
    j loop_start

loop_end:
    # Epilogue

    jr ra

error:
    li a0, 36
    j exit

.globl argmax

.text
# =================================================================
# FUNCTION: Given a int array, return the index of the largest
#   element. If there are multiple, return the one
#   with the smallest index.
# Arguments:
#   a0 (int*) is the pointer to the start of the array
#   a1 (int)  is the # of elements in the array
# Returns:
#   a0 (int)  is the first index of the largest element
# Exceptions:
#   - If the length of the array is less than 1,
#     this function terminates the program with error code 36
# =================================================================
argmax:
    # Prologue
    li t0, 1
    blt a1, t0, error   # if length < 1, terminate with error code 36

    lw t1, 0(a0)        # t1 = current maximum value = array[0]
    li t2, 0            # t2 = index of current maximum = 0
    li t3, 1            # t3 = loop index i = 1

loop_start:
    bge t3, a1, loop_end    # while (i < length)

    slli t4, t3, 2          # t4 = i * 4
    add t5, a0, t4          # t5 = &array[i]
    lw t6, 0(t5)            # t6 = array[i]

    ble t6, t1, loop_continue   # if array[i] <= max, keep current (ties -> smaller index)
    mv t1, t6                   # new max value
    mv t2, t3                   # new max index

loop_continue:
    addi t3, t3, 1          # i++
    j loop_start

loop_end:
    # Epilogue
    mv a0, t2               # return the index of the largest element

    jr ra

error:
    li a0, 36
    j exit

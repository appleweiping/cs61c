.globl dot

.text
# =======================================================
# FUNCTION: Dot product of 2 int arrays
# Arguments:
#   a0 (int*) is the pointer to the start of arr0
#   a1 (int*) is the pointer to the start of arr1
#   a2 (int)  is the number of elements to use
#   a3 (int)  is the stride of arr0
#   a4 (int)  is the stride of arr1
# Returns:
#   a0 (int)  is the dot product of arr0 and arr1
# Exceptions:
#   - If the number of elements to use is less than 1,
#     this function terminates the program with error code 36
#   - If the stride of either array is less than 1,
#     this function terminates the program with error code 37
# =======================================================
dot:

    # Prologue
    li t0, 1
    blt a2, t0, error36     # if number of elements < 1 -> error 36
    blt a3, t0, error37     # if stride of arr0 < 1     -> error 37
    blt a4, t0, error37     # if stride of arr1 < 1     -> error 37

    li t1, 0                # t1 = accumulated sum = 0
    li t2, 0                # t2 = loop index i = 0
    mv t3, a0               # t3 = running pointer into arr0
    mv t4, a1               # t4 = running pointer into arr1
    slli t5, a3, 2          # t5 = stride0 in bytes (stride0 * 4)
    slli t6, a4, 2          # t6 = stride1 in bytes (stride1 * 4)

loop_start:
    bge t2, a2, loop_end    # while (i < num_elements)

    lw a5, 0(t3)            # a5 = arr0[i * stride0]
    lw a6, 0(t4)            # a6 = arr1[i * stride1]
    mul a7, a5, a6          # a7 = product of the two elements
    add t1, t1, a7          # sum += product

    add t3, t3, t5          # advance arr0 pointer by stride0 bytes
    add t4, t4, t6          # advance arr1 pointer by stride1 bytes
    addi t2, t2, 1          # i++
    j loop_start

loop_end:
    # Epilogue
    mv a0, t1               # return the accumulated dot product

    jr ra

error36:
    li a0, 36
    j exit

error37:
    li a0, 37
    j exit

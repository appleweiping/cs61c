.globl abs

.text
# =================================================================
# FUNCTION: Given an int return its absolute value.
# Arguments:
#   a0 (int*) is a pointer to the input integer
# Returns:
#   None
# =================================================================
abs:
    # Prologue

    lw t0, 0(a0)        # t0 = *a0 (the integer)
    bge t0, zero, done  # if t0 >= 0, it is already its absolute value
    sub t0, zero, t0    # otherwise negate: t0 = 0 - t0
    sw t0, 0(a0)        # store the absolute value back to *a0

done:
    # Epilogue

    jr ra

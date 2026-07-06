import sys
import unittest
from framework import AssemblyTest, print_coverage, _venus_default_args
from tools.check_hashes import check_hashes

"""
Coverage tests for project 2 is meant to make sure you understand
how to test RISC-V code based on function descriptions.
Before you attempt to write these tests, it might be helpful to read
unittests.py and framework.py.
Like project 1, you can see your coverage score by submitting to gradescope.
The coverage will be determined by how many lines of code your tests run,
so remember to test for the exceptions!
"""

"""
abs_loss
# =======================================================
# FUNCTION: Get the absolute difference of 2 int arrays,
#   store in the result array and compute the sum
# Arguments:
#   a0 (int*) is the pointer to the start of arr0
#   a1 (int*) is the pointer to the start of arr1
#   a2 (int)  is the length of the arrays
#   a3 (int*) is the pointer to the start of the result array

# Returns:
#   a0 (int)  is the sum of the absolute loss
# Exceptions:
# - If the length of the array is less than 1,
#   this function terminates the program with error code 36.
# =======================================================
"""


class TestAbsLoss(unittest.TestCase):
    def test_simple(self):
        # load the test for abs_loss.s
        t = AssemblyTest(self, "../coverage-src/abs_loss.s")

        # arr0 and arr1 chosen so both sub1 (t5 > t6) and sub2 (t6 >= t5)
        # branches are exercised.
        array0 = t.array([1, 5, 3, 10])
        t.input_array("a0", array0)
        array1 = t.array([4, 2, 3, 1])
        t.input_array("a1", array1)
        # length of the arrays
        t.input_scalar("a2", 4)
        # result array (initialized with sentinel -1 values)
        result = t.array([-1, -1, -1, -1])
        t.input_array("a3", result)
        # call abs_loss
        t.call("abs_loss")
        # |1-4| + |5-2| + |3-3| + |10-1| = 3 + 3 + 0 + 9 = 15
        t.check_array(result, [3, 3, 0, 9])
        t.check_scalar("a0", 15)
        t.execute()

    def test_bad_length(self):
        # exercise the exit_bad_len path (length < 1 -> exit code 36)
        t = AssemblyTest(self, "../coverage-src/abs_loss.s")
        array0 = t.array([1, 2, 3])
        t.input_array("a0", array0)
        array1 = t.array([1, 2, 3])
        t.input_array("a1", array1)
        t.input_scalar("a2", 0)
        result = t.array([-1, -1, -1])
        t.input_array("a3", result)
        t.call("abs_loss")
        t.execute(code=36)

    @classmethod
    def tearDownClass(cls):
        print_coverage("abs_loss.s", verbose=False)


"""
squared_loss
# =======================================================
# FUNCTION: Get the squared difference of 2 int arrays,
#   store in the result array and compute the sum
# Arguments:
#   a0 (int*) is the pointer to the start of arr0
#   a1 (int*) is the pointer to the start of arr1
#   a2 (int)  is the length of the arrays
#   a3 (int*) is the pointer to the start of the result array

# Returns:
#   a0 (int)  is the sum of the squared loss
# Exceptions:
# - If the length of the array is less than 1,
#   this function terminates the program with error code 36.
# =======================================================
"""


class TestSquaredLoss(unittest.TestCase):
    def test_simple(self):
        # load the test for squared_loss.s
        t = AssemblyTest(self, "../coverage-src/squared_loss.s")

        array0 = t.array([1, 5, 3, 10])
        t.input_array("a0", array0)
        array1 = t.array([4, 2, 3, 1])
        t.input_array("a1", array1)
        t.input_scalar("a2", 4)
        result = t.array([-1, -1, -1, -1])
        t.input_array("a3", result)
        t.call("squared_loss")
        # (1-4)^2 + (5-2)^2 + (3-3)^2 + (10-1)^2 = 9 + 9 + 0 + 81 = 99
        t.check_array(result, [9, 9, 0, 81])
        t.check_scalar("a0", 99)
        t.execute()

    def test_bad_length(self):
        t = AssemblyTest(self, "../coverage-src/squared_loss.s")
        array0 = t.array([1, 2, 3])
        t.input_array("a0", array0)
        array1 = t.array([1, 2, 3])
        t.input_array("a1", array1)
        t.input_scalar("a2", -1)
        result = t.array([-1, -1, -1])
        t.input_array("a3", result)
        t.call("squared_loss")
        t.execute(code=36)

    @classmethod
    def tearDownClass(cls):
        print_coverage("squared_loss.s", verbose=False)


"""
zero_one_loss
# =======================================================
# FUNCTION: Generates a 0-1 classifer array inplace in the result array,
#  where result[i] = (arr0[i] == arr1[i])
# Arguments:
#   a0 (int*) is the pointer to the start of arr0
#   a1 (int*) is the pointer to the start of arr1
#   a2 (int)  is the length of the arrays
#   a3 (int*) is the pointer to the start of the result array

# Returns:
#   NONE
# Exceptions:
# - If the length of the array is less than 1,
#   this function terminates the program with error code 36.
# =======================================================
"""


class TestZeroOneLoss(unittest.TestCase):
    def test_simple(self):
        # load the test for zero_one_loss.s
        t = AssemblyTest(self, "../coverage-src/zero_one_loss.s")

        # Mix of equal (-> 1) and unequal (-> 0) elements to hit load1 and load0.
        array0 = t.array([1, 2, 3, 4])
        t.input_array("a0", array0)
        array1 = t.array([1, 9, 3, 8])
        t.input_array("a1", array1)
        t.input_scalar("a2", 4)
        result = t.array([-1, -1, -1, -1])
        t.input_array("a3", result)
        t.call("zero_one_loss")
        # result[i] = (arr0[i] == arr1[i]) -> [1, 0, 1, 0]
        t.check_array(result, [1, 0, 1, 0])
        t.execute()

    def test_bad_length(self):
        t = AssemblyTest(self, "../coverage-src/zero_one_loss.s")
        array0 = t.array([1, 2, 3])
        t.input_array("a0", array0)
        array1 = t.array([1, 2, 3])
        t.input_array("a1", array1)
        t.input_scalar("a2", 0)
        result = t.array([-1, -1, -1])
        t.input_array("a3", result)
        t.call("zero_one_loss")
        t.execute(code=36)

    @classmethod
    def tearDownClass(cls):
        print_coverage("zero_one_loss.s", verbose=False)


"""
initialize_zero
# =======================================================
# FUNCTION: Initialize a zero array with the given length
# Arguments:
#   a0 (int) size of the array

# Returns:
#   a0 (int*)  is the pointer to the zero array
# Exceptions:
# - If the length of the array is less than 1,
#   this function terminates the program with error code 36.
# - If malloc fails, this function terminates the program with exit code 26.
# =======================================================
"""


class TestInitializeZero(unittest.TestCase):
    def test_simple(self):
        t = AssemblyTest(self, "../coverage-src/initialize_zero.s")

        # allocate and zero-initialize an array of length 5
        t.input_scalar("a0", 5)
        t.call("initialize_zero")
        # the returned pointer should reference an array of five zeros
        t.check_array_pointer("a0", [0, 0, 0, 0, 0])
        t.execute()

    def test_bad_length(self):
        t = AssemblyTest(self, "../coverage-src/initialize_zero.s")
        t.input_scalar("a0", 0)
        t.call("initialize_zero")
        t.execute(code=36)

    def test_malloc_fail(self):
        t = AssemblyTest(self, "../coverage-src/initialize_zero.s")
        t.input_scalar("a0", 4)
        t.call("initialize_zero")
        # force malloc to fail so the error_malloc path (exit 26) is covered
        t.execute(fail="malloc", code=26)

    @classmethod
    def tearDownClass(cls):
        print_coverage("initialize_zero.s", verbose=False)


if __name__ == "__main__":
    split_idx = sys.argv.index("--")
    for arg in sys.argv[split_idx + 1 :]:
        _venus_default_args.append(arg)

    check_hashes()

    unittest.main(argv=sys.argv[:split_idx])

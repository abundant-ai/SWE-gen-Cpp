#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/python/test"
cp "/tests/modules/python/test/test_misc.py" "modules/python/test/test_misc.py"
mkdir -p "modules/python/test"
cp "/tests/modules/python/test/tests_common.py" "modules/python/test/tests_common.py"

checks_passed=0
checks_failed=0

# PR #12054: Add bindings utility functions for debugging InputArray types

# Check 1: bindings_utils.hpp should be present in modules/core/include/opencv2/core/
if [ -f "modules/core/include/opencv2/core/bindings_utils.hpp" ]; then
    echo "PASS: bindings_utils.hpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: bindings_utils.hpp should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: bindings_utils.cpp should be present in modules/core/src/
if [ -f "modules/core/src/bindings_utils.cpp" ]; then
    echo "PASS: bindings_utils.cpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: bindings_utils.cpp should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: dumpInputArray should be declared in bindings_utils.hpp
if grep -q 'CV_EXPORTS_W String dumpInputArray(InputArray argument)' modules/core/include/opencv2/core/bindings_utils.hpp 2>/dev/null; then
    echo "PASS: bindings_utils.hpp declares dumpInputArray function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: bindings_utils.hpp should declare dumpInputArray function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: dumpInputArrayOfArrays should be declared in bindings_utils.hpp
if grep -q 'CV_EXPORTS_W String dumpInputArrayOfArrays(InputArrayOfArrays argument)' modules/core/include/opencv2/core/bindings_utils.hpp 2>/dev/null; then
    echo "PASS: bindings_utils.hpp declares dumpInputArrayOfArrays function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: bindings_utils.hpp should declare dumpInputArrayOfArrays function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: dumpInputOutputArray should be declared in bindings_utils.hpp
if grep -q 'CV_EXPORTS_W String dumpInputOutputArray(InputOutputArray argument)' modules/core/include/opencv2/core/bindings_utils.hpp 2>/dev/null; then
    echo "PASS: bindings_utils.hpp declares dumpInputOutputArray function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: bindings_utils.hpp should declare dumpInputOutputArray function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: dumpInputOutputArrayOfArrays should be declared in bindings_utils.hpp
if grep -q 'CV_EXPORTS_W String dumpInputOutputArrayOfArrays(InputOutputArrayOfArrays argument)' modules/core/include/opencv2/core/bindings_utils.hpp 2>/dev/null; then
    echo "PASS: bindings_utils.hpp declares dumpInputOutputArrayOfArrays function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: bindings_utils.hpp should declare dumpInputOutputArrayOfArrays function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_misc.py should contain the Arguments class with test_InputArray
if grep -q 'class Arguments(NewOpenCVTests):' modules/python/test/test_misc.py 2>/dev/null; then
    echo "PASS: test_misc.py contains Arguments class"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_misc.py should contain Arguments class" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_misc.py should contain test_InputArray method
if grep -q 'def test_InputArray(self):' modules/python/test/test_misc.py 2>/dev/null; then
    echo "PASS: test_misc.py contains test_InputArray method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_misc.py should contain test_InputArray method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: test_misc.py should contain test_InputArrayOfArrays method
if grep -q 'def test_InputArrayOfArrays(self):' modules/python/test/test_misc.py 2>/dev/null; then
    echo "PASS: test_misc.py contains test_InputArrayOfArrays method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_misc.py should contain test_InputArrayOfArrays method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: test_misc.py should use cv.utils.dumpInputArray
if grep -q 'cv.utils.dumpInputArray' modules/python/test/test_misc.py 2>/dev/null; then
    echo "PASS: test_misc.py uses cv.utils.dumpInputArray"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_misc.py should use cv.utils.dumpInputArray" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: tests_common.py should have None check for iscolor parameter (fixed version)
if grep -A 2 'def get_sample(self, filename, iscolor = None):' modules/python/test/tests_common.py 2>/dev/null | grep -q 'if iscolor is None:'; then
    echo "PASS: tests_common.py has None check for iscolor parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: tests_common.py should have None check for iscolor parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: bindings_utils.cpp should implement dumpInputArray
if grep -q 'String dumpInputArray(InputArray argument)' modules/core/src/bindings_utils.cpp 2>/dev/null; then
    echo "PASS: bindings_utils.cpp implements dumpInputArray"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: bindings_utils.cpp should implement dumpInputArray" >&2
    checks_failed=$((checks_failed + 1))
fi

echo "Checks passed: $checks_passed, Checks failed: $checks_failed"

if [ $checks_failed -eq 0 ]; then
    test_status=0
else
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

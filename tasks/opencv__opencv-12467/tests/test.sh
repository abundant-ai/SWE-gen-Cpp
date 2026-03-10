#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_io.cpp" "modules/core/test/test_io.cpp"
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_ptr.cpp" "modules/core/test/test_ptr.cpp"
mkdir -p "modules/ml/test"
cp "/tests/modules/ml/test/test_mltests2.cpp" "modules/ml/test/test_mltests2.cpp"

checks_passed=0
checks_failed=0

# PR #12467: Refactor smart pointer implementations into separate header
# For harbor testing:
# - HEAD (df8b057b443c9feecc22b32141363ae7d1838030): Fixed version with cvstd_wrapper.hpp
# - BASE (after bug.patch): Buggy version with inlined code (no separate header)
# - FIXED (after oracle applies fix): Back to fixed version with cvstd_wrapper.hpp

# Check 1: cvstd.hpp SHOULD include cvstd_wrapper.hpp (fixed version)
if grep -q '#include "cvstd_wrapper.hpp"' modules/core/include/opencv2/core/cvstd.hpp; then
    echo "PASS: cvstd.hpp includes cvstd_wrapper.hpp - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cvstd.hpp missing include for cvstd_wrapper.hpp - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: cvstd_wrapper.hpp SHOULD exist as a separate file (fixed version)
if [ -f modules/core/include/opencv2/core/cvstd_wrapper.hpp ]; then
    echo "PASS: cvstd_wrapper.hpp exists as separate file - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cvstd_wrapper.hpp file does not exist - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: cvstd_wrapper.hpp SHOULD contain Ptr struct definition (fixed version)
if [ -f modules/core/include/opencv2/core/cvstd_wrapper.hpp ] && grep -q 'struct Ptr' modules/core/include/opencv2/core/cvstd_wrapper.hpp; then
    echo "PASS: cvstd_wrapper.hpp contains Ptr struct definition - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cvstd_wrapper.hpp missing or doesn't contain Ptr struct - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: cvstd_wrapper.hpp SHOULD contain DefaultDeleter (fixed version)
if [ -f modules/core/include/opencv2/core/cvstd_wrapper.hpp ] && grep -q 'struct DefaultDeleter' modules/core/include/opencv2/core/cvstd_wrapper.hpp; then
    echo "PASS: cvstd_wrapper.hpp contains DefaultDeleter - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cvstd_wrapper.hpp missing or doesn't contain DefaultDeleter - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: cvstd.hpp SHOULD NOT have inlined Ptr definition (fixed version removes it)
if ! grep -q 'struct Ptr' modules/core/include/opencv2/core/cvstd.hpp; then
    echo "PASS: cvstd.hpp does not have inlined Ptr struct - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cvstd.hpp still has inlined Ptr struct - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: cvstd.hpp SHOULD NOT have inlined DefaultDeleter (fixed version removes it)
if ! grep -A5 'struct DefaultDeleter' modules/core/include/opencv2/core/cvstd.hpp | grep -q 'void operator ()'; then
    echo "PASS: cvstd.hpp does not have inlined DefaultDeleter - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cvstd.hpp still has inlined DefaultDeleter - buggy version" >&2
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

#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "samples/cpp/tutorial_code/compatibility"
cp "/tests/samples/cpp/tutorial_code/compatibility/compatibility_test.cpp" "samples/cpp/tutorial_code/compatibility/compatibility_test.cpp"

checks_passed=0
checks_failed=0

# PR #13253: The PR adds legacy compatibility headers support to OpenCV
# For harbor testing:
# - HEAD (562676c5dae4d25b00f88556bd8de99330d4e484): legacy/*.h patterns in CMakeLists, test file exists (fixed version)
# - BASE (after bug.patch): legacy/*.h patterns removed, test file removed (buggy version)
# - FIXED (after fix.patch): legacy/*.h patterns added back, test file added back (back to HEAD)

# Check 1: cmake/OpenCVModule.cmake should include legacy/*.h pattern
if grep -q '"\${CMAKE_CURRENT_LIST_DIR}/include/opencv2/\${name}/legacy/\*.h"' cmake/OpenCVModule.cmake; then
    echo "PASS: cmake/OpenCVModule.cmake includes legacy/*.h pattern (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cmake/OpenCVModule.cmake missing legacy/*.h pattern (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: modules/imgcodecs/CMakeLists.txt should include legacy/*.h pattern
if grep -q '"\${CMAKE_CURRENT_LIST_DIR}/include/opencv2/\${name}/legacy/\*.h"' modules/imgcodecs/CMakeLists.txt; then
    echo "PASS: modules/imgcodecs/CMakeLists.txt includes legacy/*.h pattern (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/imgcodecs/CMakeLists.txt missing legacy/*.h pattern (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: modules/videoio/CMakeLists.txt should include legacy/*.h pattern
if grep -q '"\${CMAKE_CURRENT_LIST_DIR}/include/opencv2/\${name}/legacy/\*.h"' modules/videoio/CMakeLists.txt; then
    echo "PASS: modules/videoio/CMakeLists.txt includes legacy/*.h pattern (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/videoio/CMakeLists.txt missing legacy/*.h pattern (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: Test file should exist and include legacy headers
if [ -f "samples/cpp/tutorial_code/compatibility/compatibility_test.cpp" ]; then
    echo "PASS: compatibility_test.cpp exists (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: compatibility_test.cpp does not exist (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: Test file should include legacy constants_c.h headers
if [ -f "samples/cpp/tutorial_code/compatibility/compatibility_test.cpp" ] && \
   grep -q "#include <opencv2/imgcodecs/legacy/constants_c.h>" samples/cpp/tutorial_code/compatibility/compatibility_test.cpp; then
    echo "PASS: compatibility_test.cpp includes imgcodecs legacy header (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: compatibility_test.cpp missing imgcodecs legacy header (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Test file should include videoio legacy header
if [ -f "samples/cpp/tutorial_code/compatibility/compatibility_test.cpp" ] && \
   grep -q "#include <opencv2/videoio/legacy/constants_c.h>" samples/cpp/tutorial_code/compatibility/compatibility_test.cpp; then
    echo "PASS: compatibility_test.cpp includes videoio legacy header (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: compatibility_test.cpp missing videoio legacy header (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: Test file should include photo legacy header
if [ -f "samples/cpp/tutorial_code/compatibility/compatibility_test.cpp" ] && \
   grep -q "#include <opencv2/photo/legacy/constants_c.h>" samples/cpp/tutorial_code/compatibility/compatibility_test.cpp; then
    echo "PASS: compatibility_test.cpp includes photo legacy header (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: compatibility_test.cpp missing photo legacy header (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: Test file should include video legacy header
if [ -f "samples/cpp/tutorial_code/compatibility/compatibility_test.cpp" ] && \
   grep -q "#include <opencv2/video/legacy/constants_c.h>" samples/cpp/tutorial_code/compatibility/compatibility_test.cpp; then
    echo "PASS: compatibility_test.cpp includes video legacy header (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: compatibility_test.cpp missing video legacy header (buggy version)" >&2
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

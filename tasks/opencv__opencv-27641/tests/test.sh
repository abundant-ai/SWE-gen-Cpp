#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgproc/test"
cp "/tests/modules/imgproc/test/test_subdivision2d.cpp" "modules/imgproc/test/test_subdivision2d.cpp"

checks_passed=0
checks_failed=0

# Check 1: Subdiv2D(Rect2f) constructor declaration exists in header
if grep -q 'CV_WRAP Subdiv2D(Rect2f rect);' modules/imgproc/include/opencv2/imgproc.hpp; then
    echo "PASS: imgproc.hpp declares Subdiv2D(Rect2f) constructor (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: imgproc.hpp missing Subdiv2D(Rect2f) constructor declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: initDelaunay(Rect2f) declaration exists in header
if grep -q 'CV_WRAP void initDelaunay(Rect2f rect);' modules/imgproc/include/opencv2/imgproc.hpp; then
    echo "PASS: imgproc.hpp declares initDelaunay(Rect2f) method (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: imgproc.hpp missing initDelaunay(Rect2f) declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: Subdiv2D(Rect2f) constructor implementation exists
if grep -q 'Subdiv2D::Subdiv2D(Rect2f rect)' modules/imgproc/src/subdivision2d.cpp; then
    echo "PASS: subdivision2d.cpp implements Subdiv2D(Rect2f) constructor (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: subdivision2d.cpp missing Subdiv2D(Rect2f) constructor implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: initDelaunay(Rect2f) implementation exists
if grep -q 'void Subdiv2D::initDelaunay( Rect2f rect )' modules/imgproc/src/subdivision2d.cpp; then
    echo "PASS: subdivision2d.cpp implements initDelaunay(Rect2f) method (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: subdivision2d.cpp missing initDelaunay(Rect2f) implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: Test for Rect2f constructor exists
if grep -q 'TEST(Imgproc_Subdiv2D, rect2f_constructor_and_init)' modules/imgproc/test/test_subdivision2d.cpp; then
    echo "PASS: test_subdivision2d.cpp contains rect2f_constructor_and_init test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_subdivision2d.cpp missing rect2f_constructor_and_init test (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: Test for Rect2f edge cases exists
if grep -q 'TEST(Imgproc_Subdiv2D, rect2f_edge_cases)' modules/imgproc/test/test_subdivision2d.cpp; then
    echo "PASS: test_subdivision2d.cpp contains rect2f_edge_cases test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_subdivision2d.cpp missing rect2f_edge_cases test (buggy version)" >&2
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

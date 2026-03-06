#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/misc/java/test"
cp "/tests/modules/dnn/misc/java/test/DnnForwardAndRetrieve.java" "modules/dnn/misc/java/test/DnnForwardAndRetrieve.java"

checks_passed=0
checks_failed=0

# Check 1: Test file should exist (fixed version)
if [ -f "modules/dnn/misc/java/test/DnnForwardAndRetrieve.java" ] && \
   grep -q 'public void testForwardAndRetrieve()' modules/dnn/misc/java/test/DnnForwardAndRetrieve.java && \
   grep -q 'List<List<Mat>> outBlobs = new ArrayList<>()' modules/dnn/misc/java/test/DnnForwardAndRetrieve.java && \
   grep -q 'net.forwardAndRetrieve(outBlobs, outNames)' modules/dnn/misc/java/test/DnnForwardAndRetrieve.java; then
    echo "PASS: Test file exists with forwardAndRetrieve test (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test file missing or incorrect (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: gen_dict.json should have vector_vector_Mat type definition (fixed version)
if grep -q '"vector_vector_Mat"' modules/core/misc/java/gen_dict.json && \
   grep -q '"j_type": "List<List<Mat>>"' modules/core/misc/java/gen_dict.json; then
    echo "PASS: gen_dict.json has vector_vector_Mat definition (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gen_dict.json missing vector_vector_Mat definition (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: converters.cpp should have vector_vector_Mat conversion functions (fixed version)
if grep -q 'void Mat_to_vector_vector_Mat' modules/java/generator/src/cpp/converters.cpp && \
   grep -q 'void vector_vector_Mat_to_Mat' modules/java/generator/src/cpp/converters.cpp; then
    echo "PASS: converters.cpp has vector_vector_Mat conversion functions (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: converters.cpp missing vector_vector_Mat conversion functions (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: converters.h should declare the conversion functions (fixed version)
if grep -q 'void Mat_to_vector_vector_Mat' modules/java/generator/src/cpp/converters.h && \
   grep -q 'void vector_vector_Mat_to_Mat' modules/java/generator/src/cpp/converters.h; then
    echo "PASS: converters.h declares vector_vector_Mat conversion functions (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: converters.h missing vector_vector_Mat conversion function declarations (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: Converters.java should have vector_vector_Mat methods (fixed version)
if grep -q 'public static Mat vector_vector_Mat_to_Mat' modules/java/generator/src/java/org/opencv/utils/Converters.java && \
   grep -q 'public static void Mat_to_vector_vector_Mat' modules/java/generator/src/java/org/opencv/utils/Converters.java; then
    echo "PASS: Converters.java has vector_vector_Mat methods (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Converters.java missing vector_vector_Mat methods (buggy version)" >&2
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

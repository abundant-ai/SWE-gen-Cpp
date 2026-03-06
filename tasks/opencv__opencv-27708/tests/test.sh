#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/misc/java/test"
cp "/tests/modules/dnn/misc/java/test/DnnListRegressionTest.java" "modules/dnn/misc/java/test/DnnListRegressionTest.java"

checks_passed=0
checks_failed=0

# Check 1: Test file should have testGetLayersShapes method (fixed version)
if grep -q 'public void testGetLayersShapes()' modules/dnn/misc/java/test/DnnListRegressionTest.java && \
   grep -q 'List<List<MatOfInt>> inLayersShapes = new ArrayList' modules/dnn/misc/java/test/DnnListRegressionTest.java && \
   grep -q 'List<List<MatOfInt>> outLayersShapes = new ArrayList' modules/dnn/misc/java/test/DnnListRegressionTest.java && \
   grep -q 'net.getLayersShapes(netInputShapes, layersIds, inLayersShapes, outLayersShapes)' modules/dnn/misc/java/test/DnnListRegressionTest.java; then
    echo "PASS: Test file has testGetLayersShapes method (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test file missing testGetLayersShapes method (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: Converters.java should have vector_vector_MatShape support (fixed version)
if grep -q 'Mat_to_vector_vector_MatShape' modules/java/generator/src/java/org/opencv/utils/Converters.java && \
   grep -q 'vector_vector_MatShape_to_Mat' modules/java/generator/src/java/org/opencv/utils/Converters.java; then
    echo "PASS: Converters.java has vector_vector_MatShape methods (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Converters.java missing vector_vector_MatShape methods (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: gen_dict.json should have vector_vector_MatShape type definition (fixed version)
if grep -q '"vector_vector_MatShape"' modules/dnn/misc/java/gen_dict.json; then
    echo "PASS: gen_dict.json has vector_vector_MatShape definition (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gen_dict.json missing vector_vector_MatShape definition (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: dnn_converters.cpp should have vector_MatShape_to_Mat and Mat_to_vector_MatShape (fixed version)
if grep -q 'void vector_MatShape_to_Mat' modules/dnn/misc/java/src/cpp/dnn_converters.cpp && \
   grep -q 'void Mat_to_vector_MatShape' modules/dnn/misc/java/src/cpp/dnn_converters.cpp; then
    echo "PASS: dnn_converters.cpp has vector_MatShape conversion functions (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn_converters.cpp missing vector_MatShape conversion functions (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: dnn_converters.cpp should have vector_vector_MatShape conversion functions (fixed version)
if grep -q 'void vector_vector_MatShape_to_Mat' modules/dnn/misc/java/src/cpp/dnn_converters.cpp && \
   grep -q 'void Mat_to_vector_vector_MatShape' modules/dnn/misc/java/src/cpp/dnn_converters.cpp; then
    echo "PASS: dnn_converters.cpp has vector_vector_MatShape conversion functions (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn_converters.cpp missing vector_vector_MatShape conversion functions (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: dnn_converters.hpp should declare the new conversion functions (fixed version)
if grep -q 'void vector_MatShape_to_Mat' modules/dnn/misc/java/src/cpp/dnn_converters.hpp && \
   grep -q 'void Mat_to_vector_MatShape' modules/dnn/misc/java/src/cpp/dnn_converters.hpp && \
   grep -q 'void vector_vector_MatShape_to_Mat' modules/dnn/misc/java/src/cpp/dnn_converters.hpp && \
   grep -q 'void Mat_to_vector_vector_MatShape' modules/dnn/misc/java/src/cpp/dnn_converters.hpp; then
    echo "PASS: dnn_converters.hpp declares conversion functions (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn_converters.hpp missing conversion function declarations (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: dnn_converters.cpp should include converters.h (fixed version)
if grep -q '#include "converters.h"' modules/dnn/misc/java/src/cpp/dnn_converters.cpp; then
    echo "PASS: dnn_converters.cpp includes converters.h (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn_converters.cpp missing converters.h include (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: Converters.java should import MatOfInt (fixed version)
if grep -q 'import org.opencv.core.MatOfInt;' modules/java/generator/src/java/org/opencv/utils/Converters.java; then
    echo "PASS: Converters.java imports MatOfInt (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Converters.java missing MatOfInt import (buggy version)" >&2
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

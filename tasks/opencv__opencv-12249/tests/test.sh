#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_darknet_importer.cpp" "modules/dnn/test/test_darknet_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12249: Add NMSBoxes overload for Rect2d and batch processing support
# The fix adds:
# 1. NMSBoxes overload with Rect2d support in dnn.hpp
# 2. Batch processing support in region_layer.cpp
# For harbor testing:
# - HEAD (3ba6be15de718fb6ef643fa7e726ff2034867dca): Fixed version with NMSBoxes Rect2d overload
# - BASE (after bug.patch): Buggy version without Rect2d overload
# - FIXED (after oracle applies fix): Back to fixed version

# Check 1: dnn.hpp should have NMSBoxes overload with Rect2d (fixed version)
if grep -q 'CV_EXPORTS_W void NMSBoxes(const std::vector<Rect2d>& bboxes, const std::vector<float>& scores,' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: dnn.hpp has NMSBoxes Rect2d overload - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp should have NMSBoxes Rect2d overload - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: region_layer.cpp should handle batch_size in getMemoryShapes (fixed version)
if grep -q 'int batch_size = inputs\[0\]\[0\];' modules/dnn/src/layers/region_layer.cpp && \
   grep -q 'if(batch_size > 1)' modules/dnn/src/layers/region_layer.cpp; then
    echo "PASS: region_layer.cpp handles batch_size in getMemoryShapes - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: region_layer.cpp should handle batch_size in getMemoryShapes - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: region_layer.cpp should use batch_size in OpenCL forward (fixed version)
if grep -q 'int batch_size = inpBlob.size\[0\];' modules/dnn/src/layers/region_layer.cpp && \
   grep -q 'size_t nanchors = rows\*cols\*anchors\*batch_size;' modules/dnn/src/layers/region_layer.cpp; then
    echo "PASS: region_layer.cpp uses batch_size in OpenCL forward - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: region_layer.cpp should use batch_size in OpenCL forward - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: region_layer.cpp should have sample_size calculation (fixed version)
if grep -q 'int sample_size = cell_size\*rows\*cols\*anchors;' modules/dnn/src/layers/region_layer.cpp; then
    echo "PASS: region_layer.cpp has sample_size calculation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: region_layer.cpp should have sample_size calculation - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: region_layer.cpp should loop over batch in do_nms_sort (fixed version)
if grep -q 'for (int b = 0; b < batch_size; ++b)' modules/dnn/src/layers/region_layer.cpp && \
   grep -A1 'for (int b = 0; b < batch_size; ++b)' modules/dnn/src/layers/region_layer.cpp | grep -q 'do_nms_sort(dstData + b\*sample_size'; then
    echo "PASS: region_layer.cpp loops over batch in do_nms_sort - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: region_layer.cpp should loop over batch in do_nms_sort - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: region_layer.cpp should have batch_size in CPU forward (fixed version)
if grep -B5 'int sample_size = cell_size\*rows\*cols\*anchors;' modules/dnn/src/layers/region_layer.cpp | grep -q 'int batch_size = inpBlob.size\[0\];'; then
    echo "PASS: region_layer.cpp has batch_size in CPU forward - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: region_layer.cpp should have batch_size in CPU forward - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: region_layer.cpp should have CV_Assert for sample_size (fixed version)
if grep -q 'CV_Assert(sample_size\*batch_size == inpBlob.total());' modules/dnn/src/layers/region_layer.cpp; then
    echo "PASS: region_layer.cpp has CV_Assert for sample_size - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: region_layer.cpp should have CV_Assert for sample_size - buggy version" >&2
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

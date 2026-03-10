#!/bin/bash

cd /app/src

# Apply fix.patch to get HEAD state for source code validation
cp /solution/fix.patch /tmp/fix.patch
git apply --reject --whitespace=fix /tmp/fix.patch || true
rm /tmp/fix.patch

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_halide_layers.cpp" "modules/dnn/test/test_halide_layers.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_misc.cpp" "modules/dnn/test/test_misc.cpp"

checks_passed=0
checks_failed=0

# PR #11781: Add normalization parameters to setInput() and ddepth parameter to blobFromImage()

# Check 1: dnn.hpp - experimental_dnn_v6 namespace should be defined
if grep -q 'namespace experimental_dnn_v6' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: experimental_dnn_v6 namespace is defined"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: experimental_dnn_v6 namespace should be defined" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: dnn.hpp - setInput() should have scalefactor parameter
if grep -A 2 'void setInput' modules/dnn/include/opencv2/dnn/dnn.hpp | grep -q 'double scalefactor'; then
    echo "PASS: setInput() has scalefactor parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: setInput() should have scalefactor parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: dnn.hpp - setInput() should have mean parameter
if grep -A 2 'void setInput' modules/dnn/include/opencv2/dnn/dnn.hpp | grep -q 'const Scalar& mean'; then
    echo "PASS: setInput() has mean parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: setInput() should have mean parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: dnn.hpp - blobFromImage() should have ddepth parameter
if grep -A 3 'Mat blobFromImage' modules/dnn/include/opencv2/dnn/dnn.hpp | grep -q 'int ddepth'; then
    echo "PASS: blobFromImage() has ddepth parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blobFromImage() should have ddepth parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: dnn.hpp - blobFromImage() overload with OutputArray should have ddepth parameter
if grep -A 3 'void blobFromImage.*OutputArray blob' modules/dnn/include/opencv2/dnn/dnn.hpp | grep -q 'int ddepth'; then
    echo "PASS: blobFromImage() overload has ddepth parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blobFromImage() overload should have ddepth parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: dnn.hpp - blobFromImages() should have ddepth parameter
if grep -A 3 'Mat blobFromImages' modules/dnn/include/opencv2/dnn/dnn.hpp | grep -q 'int ddepth'; then
    echo "PASS: blobFromImages() has ddepth parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blobFromImages() should have ddepth parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: dnn.hpp - blobFromImages() overload with OutputArray should have ddepth parameter
if grep -A 3 'void blobFromImages.*OutputArray blob' modules/dnn/include/opencv2/dnn/dnn.hpp | grep -q 'int ddepth'; then
    echo "PASS: blobFromImages() overload has ddepth parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blobFromImages() overload should have ddepth parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: dnn.cpp - blobFromImages() should check ddepth is CV_32F or CV_8U
if grep -q 'CV_CheckType(ddepth, ddepth == CV_32F || ddepth == CV_8U' modules/dnn/src/dnn.cpp; then
    echo "PASS: blobFromImages() validates ddepth parameter"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blobFromImages() should validate ddepth parameter" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: dnn.cpp - blobFromImages() should check CV_8U doesn't support scaling
if grep -q 'Scaling is not supported for CV_8U blob depth' modules/dnn/src/dnn.cpp; then
    echo "PASS: blobFromImages() rejects scaling for CV_8U"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blobFromImages() should reject scaling for CV_8U" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: dnn.cpp - blobFromImages() should check CV_8U doesn't support mean subtraction
if grep -q 'Mean subtraction is not supported for CV_8U blob depth' modules/dnn/src/dnn.cpp; then
    echo "PASS: blobFromImages() rejects mean subtraction for CV_8U"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blobFromImages() should reject mean subtraction for CV_8U" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: dnn.cpp - blobFromImages() should only convert CV_8U to CV_32F when ddepth is CV_32F
if grep -q 'if(images\[i\]\.depth() == CV_8U && ddepth == CV_32F)' modules/dnn/src/dnn.cpp; then
    echo "PASS: blobFromImages() conditionally converts CV_8U based on ddepth"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blobFromImages() should conditionally convert CV_8U based on ddepth" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: dnn.cpp - blobFromImages() should create blob with specified ddepth
if grep -q 'blob_\.create(4, sz, ddepth)' modules/dnn/src/dnn.cpp; then
    echo "PASS: blobFromImages() creates blob with specified ddepth"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blobFromImages() should create blob with specified ddepth" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: dnn.cpp - DataLayer should have scaleFactors member variable
if grep -q 'std::vector<double> scaleFactors' modules/dnn/src/dnn.cpp; then
    echo "PASS: DataLayer has scaleFactors member"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: DataLayer should have scaleFactors member" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: dnn.cpp - DataLayer should have means member variable
if grep -q 'std::vector<Scalar> means' modules/dnn/src/dnn.cpp; then
    echo "PASS: DataLayer has means member"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: DataLayer should have means member" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: dnn.cpp - DataLayer should apply scaling and mean subtraction
if grep -q 'convertTo.*scale.*-mean' modules/dnn/src/dnn.cpp; then
    echo "PASS: DataLayer applies scaling and mean subtraction"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: DataLayer should apply scaling and mean subtraction" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: dnn.cpp - DataLayer should support backends
if grep -A 3 'virtual bool supportBackend' modules/dnn/src/dnn.cpp | grep -q 'DNN_BACKEND_INFERENCE_ENGINE'; then
    echo "PASS: DataLayer implements supportBackend()"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: DataLayer should implement supportBackend()" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 17: dnn.cpp - DataLayer should initialize InferenceEngine backend node
if grep -q 'Ptr<BackendNode> initInfEngine' modules/dnn/src/dnn.cpp; then
    echo "PASS: DataLayer implements initInfEngine()"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: DataLayer should implement initInfEngine()" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 18: dnn.cpp - setInput() should store scalefactor
if grep -q 'netInputLayer->scaleFactors\[.*\] = scalefactor' modules/dnn/src/dnn.cpp; then
    echo "PASS: setInput() stores scalefactor"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: setInput() should store scalefactor" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 19: dnn.cpp - setInput() should store mean
if grep -q 'netInputLayer->means\[.*\] = mean' modules/dnn/src/dnn.cpp; then
    echo "PASS: setInput() stores mean"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: setInput() should store mean" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 20: op_inf_engine.cpp - wrapToInfEngineDataNode should support CV_8U
if grep -q 'InferenceEngine::Precision::U8' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: InferenceEngine wrapper supports CV_8U precision"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: InferenceEngine wrapper should support CV_8U precision" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 21: op_inf_engine.cpp - wrapToInfEngineBlob should handle CV_8U type
if grep -q 'make_shared_blob<uint8_t>' modules/dnn/src/op_inf_engine.cpp; then
    echo "PASS: wrapToInfEngineBlob creates uint8_t blobs"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: wrapToInfEngineBlob should create uint8_t blobs" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 22: op_inf_engine.hpp - InfEngineBackendWrapper should use generic Blob::Ptr
if grep -q 'InferenceEngine::Blob::Ptr blob' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: InfEngineBackendWrapper uses generic Blob::Ptr"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: InfEngineBackendWrapper should use generic Blob::Ptr" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 23: op_inf_engine.hpp - wrapToInfEngineBlob should return generic Blob::Ptr
if grep -q 'InferenceEngine::Blob::Ptr wrapToInfEngineBlob' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: wrapToInfEngineBlob returns generic Blob::Ptr"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: wrapToInfEngineBlob should return generic Blob::Ptr" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 24: op_inf_engine.hpp - InfEngineBackendWrapper should have create() method
if grep -q 'static Ptr<BackendWrapper> create' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: InfEngineBackendWrapper has create() method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: InfEngineBackendWrapper should have create() method" >&2
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

#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"

checks_passed=0
checks_failed=0

# PR #11812: Add InterpLayer implementation to DNN module

# Check 1: all_layers.hpp - InterpLayer class should be declared
if grep -q 'class CV_EXPORTS InterpLayer : public Layer' modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "PASS: InterpLayer class is declared in all_layers.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: InterpLayer class should be declared in all_layers.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: all_layers.hpp - InterpLayer should have create method
if grep -A 6 'class CV_EXPORTS InterpLayer' modules/dnn/include/opencv2/dnn/all_layers.hpp | grep -q 'static Ptr<Layer> create(const LayerParams& params)'; then
    echo "PASS: InterpLayer has create method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: InterpLayer should have static create method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: all_layers.hpp - InterpLayer should have documentation mentioning bilinear resize
if grep -B 5 'class CV_EXPORTS InterpLayer' modules/dnn/include/opencv2/dnn/all_layers.hpp | grep -q 'Bilinear resize layer'; then
    echo "PASS: InterpLayer has documentation about bilinear resize"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: InterpLayer should have documentation mentioning bilinear resize" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: init.cpp - Interp layer should be registered
if grep -q 'CV_DNN_REGISTER_LAYER_CLASS(Interp,         InterpLayer)' modules/dnn/src/init.cpp; then
    echo "PASS: Interp layer is registered in init.cpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Interp layer should be registered with CV_DNN_REGISTER_LAYER_CLASS" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: resize_layer.cpp - ResizeLayerImpl should NOT be marked as CV_FINAL (to allow inheritance)
if grep -q 'class ResizeLayerImpl : public ResizeLayer' modules/dnn/src/layers/resize_layer.cpp; then
    echo "PASS: ResizeLayerImpl allows inheritance (not marked CV_FINAL)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ResizeLayerImpl should allow inheritance by InterpLayerImpl" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: resize_layer.cpp - ResizeLayerImpl members should be protected (not private)
if grep -q 'protected:' modules/dnn/src/layers/resize_layer.cpp && \
   grep -A 3 'protected:' modules/dnn/src/layers/resize_layer.cpp | grep -q 'int outWidth, outHeight'; then
    echo "PASS: ResizeLayerImpl has protected members for subclass access"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ResizeLayerImpl members should be protected to allow subclass access" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: resize_layer.cpp - ResizeLayerImpl should store scaleWidth and scaleHeight as members
if grep -A 3 'protected:' modules/dnn/src/layers/resize_layer.cpp | grep -q 'float scaleWidth, scaleHeight'; then
    echo "PASS: ResizeLayerImpl has scaleWidth and scaleHeight as members"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ResizeLayerImpl should have scaleWidth and scaleHeight as members" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: resize_layer.cpp - InterpLayerImpl class should exist
if grep -q 'class InterpLayerImpl CV_FINAL : public ResizeLayerImpl' modules/dnn/src/layers/resize_layer.cpp; then
    echo "PASS: InterpLayerImpl class is implemented"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: InterpLayerImpl should be implemented as subclass of ResizeLayerImpl" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: resize_layer.cpp - InterpLayerImpl should override getMemoryShapes
if grep -A 25 'class InterpLayerImpl CV_FINAL' modules/dnn/src/layers/resize_layer.cpp | grep -q 'getMemoryShapes'; then
    echo "PASS: InterpLayerImpl overrides getMemoryShapes"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: InterpLayerImpl should override getMemoryShapes" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: resize_layer.cpp - InterpLayerImpl should override finalize method
if grep -A 30 'class InterpLayerImpl' modules/dnn/src/layers/resize_layer.cpp | grep -q 'virtual void finalize.*CV_OVERRIDE'; then
    echo "PASS: InterpLayerImpl overrides finalize method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: InterpLayerImpl should override finalize method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: resize_layer.cpp - InterpLayerImpl finalize should compute scale differently (align-corners style)
if grep -A 40 'class InterpLayerImpl' modules/dnn/src/layers/resize_layer.cpp | \
   grep -q 'scaleHeight = (outHeight > 1) ? (static_cast<float>(inpHeight - 1) / (outHeight - 1)) : 0.f'; then
    echo "PASS: InterpLayerImpl uses align-corners style scale computation"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: InterpLayerImpl should compute scaleHeight with align-corners formula" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: resize_layer.cpp - InterpLayer::create factory method should exist
if grep -q 'Ptr<Layer> InterpLayer::create(const LayerParams& params)' modules/dnn/src/layers/resize_layer.cpp; then
    echo "PASS: InterpLayer::create factory method exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: InterpLayer should have create factory method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: resize_layer.cpp - InterpLayer::create should set interpolation to bilinear
if grep -A 4 'Ptr<Layer> InterpLayer::create' modules/dnn/src/layers/resize_layer.cpp | \
   grep -q 'lp.set("interpolation", "bilinear")'; then
    echo "PASS: InterpLayer::create sets interpolation to bilinear"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: InterpLayer::create should set interpolation to bilinear" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: resize_layer.cpp - InterpLayer::create should return InterpLayerImpl instance
if grep -A 5 'Ptr<Layer> InterpLayer::create' modules/dnn/src/layers/resize_layer.cpp | \
   grep -q 'return Ptr<Layer>(new InterpLayerImpl(lp))'; then
    echo "PASS: InterpLayer::create returns InterpLayerImpl instance"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: InterpLayer::create should return InterpLayerImpl instance" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: resize_layer.cpp - finalize should compute scaleHeight/scaleWidth in base class
if grep 'scaleHeight = static_cast<float>(inputs\[0\]->size\[2\]) / outHeight' modules/dnn/src/layers/resize_layer.cpp; then
    echo "PASS: ResizeLayerImpl finalize computes scale factors"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ResizeLayerImpl finalize should compute scaleHeight and scaleWidth" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: test_layers.cpp - Test should be named Layer_Test_Interp (not Layer_Test_Interp_custom)
if grep -q 'TEST(Layer_Test_Interp, Accuracy)' modules/dnn/test/test_layers.cpp; then
    echo "PASS: Test is named Layer_Test_Interp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test should be named TEST(Layer_Test_Interp, Accuracy)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 17: test_layers.cpp - Test should call testLayerUsingCaffeModels
if grep -A 3 'TEST(Layer_Test_Interp, Accuracy)' modules/dnn/test/test_layers.cpp | \
   grep -q 'testLayerUsingCaffeModels'; then
    echo "PASS: Test calls testLayerUsingCaffeModels"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Test should call testLayerUsingCaffeModels" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 18: test_layers.cpp - After fix, there should be both Layer_Test_Interp_custom and Layer_Test_Interp tests
if grep -q 'TEST(Layer_Test_Interp_custom, Accuracy)' modules/dnn/test/test_layers.cpp && \
   grep 'TEST(Layer_Test_Interp, Accuracy)' modules/dnn/test/test_layers.cpp | grep -v '_custom' | grep -q 'TEST'; then
    echo "PASS: Both Layer_Test_Interp tests exist (custom and non-custom)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Should have both Layer_Test_Interp_custom and Layer_Test_Interp tests after fix" >&2
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

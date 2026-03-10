#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_caffe_importer.cpp" "modules/dnn/test/test_caffe_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_torch_importer.cpp" "modules/dnn/test/test_torch_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12364: Update experimental_dnn namespace and change default parameters for blobFromImage/blobFromImages
# For harbor testing:
# - HEAD (58ac3e09da332cd23126500b9e49059633522c5a): Fixed version with v9 namespace and swapRB=false, crop=false defaults
# - BASE (after bug.patch): Buggy version with v8 namespace and swapRB=true, crop=true defaults
# - FIXED (after oracle applies fix): Back to fixed version with v9 and correct defaults
#
# Note: Test files are always copied from /tests (HEAD version), so they're always fixed.
# We only check non-test files that are patched by fix.patch.

# Check 1: dnn.hpp should have experimental_dnn_34_v9 namespace (fixed version)
if grep -q '#define CV__DNN_EXPERIMENTAL_NS_BEGIN namespace experimental_dnn_34_v9 {' modules/dnn/include/opencv2/dnn/dnn.hpp && \
   grep -q 'namespace cv { namespace dnn { namespace experimental_dnn_34_v9 { } using namespace experimental_dnn_34_v9; }}' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: dnn.hpp has experimental_dnn_34_v9 namespace - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp has wrong namespace (should be experimental_dnn_34_v9) - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: blobFromImage (Mat return) should have swapRB=false, crop=false defaults (fixed version)
if grep -q 'CV_EXPORTS_W Mat blobFromImage(InputArray image, double scalefactor=1.0, const Size& size = Size(),' modules/dnn/include/opencv2/dnn/dnn.hpp && \
   grep -q 'const Scalar& mean = Scalar(), bool swapRB=false, bool crop=false,' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: blobFromImage (Mat) has swapRB=false, crop=false defaults - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blobFromImage (Mat) has wrong defaults (should be swapRB=false, crop=false) - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: blobFromImage (void with OutputArray) should have swapRB=false, crop=false defaults (fixed version)
if grep -q 'CV_EXPORTS void blobFromImage(InputArray image, OutputArray blob, double scalefactor=1.0,' modules/dnn/include/opencv2/dnn/dnn.hpp && \
   grep -q 'const Size& size = Size(), const Scalar& mean = Scalar(),' modules/dnn/include/opencv2/dnn/dnn.hpp && \
   grep -q 'bool swapRB=false, bool crop=false, int ddepth=CV_32F);' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: blobFromImage (void) has swapRB=false, crop=false defaults - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blobFromImage (void) has wrong defaults (should be swapRB=false, crop=false) - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: blobFromImages (Mat return) should have swapRB=false, crop=false defaults (fixed version)
if grep -q 'CV_EXPORTS_W Mat blobFromImages(InputArrayOfArrays images, double scalefactor=1.0,' modules/dnn/include/opencv2/dnn/dnn.hpp && \
   grep -q 'Size size = Size(), const Scalar& mean = Scalar(), bool swapRB=false, bool crop=false,' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: blobFromImages (Mat) has swapRB=false, crop=false defaults - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blobFromImages (Mat) has wrong defaults (should be swapRB=false, crop=false) - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: blobFromImages (void with OutputArray) should have swapRB=false, crop=false defaults (fixed version)
if grep -q 'CV_EXPORTS void blobFromImages(InputArrayOfArrays images, OutputArray blob,' modules/dnn/include/opencv2/dnn/dnn.hpp && \
   grep -q 'double scalefactor=1.0, Size size = Size(),' modules/dnn/include/opencv2/dnn/dnn.hpp && \
   grep -q 'const Scalar& mean = Scalar(), bool swapRB=false, bool crop=false,' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: blobFromImages (void) has swapRB=false, crop=false defaults - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: blobFromImages (void) has wrong defaults (should be swapRB=false, crop=false) - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: MainActivity.java should have explicit swapRB and crop parameters (fixed version)
if grep -q 'new Scalar(MEAN_VAL, MEAN_VAL, MEAN_VAL), /\*swapRB\*/false, /\*crop\*/false);' samples/android/mobilenet-objdetect/src/org/opencv/samples/opencv_mobilenet/MainActivity.java; then
    echo "PASS: MainActivity.java has explicit swapRB=false, crop=false parameters - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MainActivity.java missing explicit parameters - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: MainActivity.java should NOT have cropSize calculation code (fixed version removes it)
if ! grep -q 'Size cropSize;' samples/android/mobilenet-objdetect/src/org/opencv/samples/opencv_mobilenet/MainActivity.java && \
   ! grep -q 'Mat subFrame = frame.submat' samples/android/mobilenet-objdetect/src/org/opencv/samples/opencv_mobilenet/MainActivity.java; then
    echo "PASS: MainActivity.java has no cropSize calculation - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MainActivity.java has cropSize calculation code - buggy version" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: MainActivity.java should use 'frame' not 'subFrame' in rectangle drawing (fixed version)
if grep -q 'Imgproc.rectangle(frame, new Point(left, top), new Point(right, bottom),' samples/android/mobilenet-objdetect/src/org/opencv/samples/opencv_mobilenet/MainActivity.java; then
    echo "PASS: MainActivity.java uses 'frame' for drawing - fixed version"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: MainActivity.java uses 'subFrame' for drawing - buggy version" >&2
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

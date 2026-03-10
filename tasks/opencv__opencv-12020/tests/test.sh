#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/python/test"
cp "/tests/modules/python/test/test_videoio.py" "modules/python/test/test_videoio.py"
mkdir -p "modules/videoio/test"
cp "/tests/modules/videoio/test/test_precomp.hpp" "modules/videoio/test/test_precomp.hpp"
mkdir -p "modules/videoio/test"
cp "/tests/modules/videoio/test/test_video_io.cpp" "modules/videoio/test/test_video_io.cpp"

checks_passed=0
checks_failed=0

# PR #12020: Add videoio_registry API for querying available backends

# Check 1: registry.hpp header file should exist
if [ -f "modules/videoio/include/opencv2/videoio/registry.hpp" ]; then
    echo "PASS: registry.hpp header file exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: registry.hpp header file should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: registry.hpp should declare getBackendName function
if grep -q "CV_EXPORTS_W cv::String getBackendName(VideoCaptureAPIs api);" modules/videoio/include/opencv2/videoio/registry.hpp 2>/dev/null; then
    echo "PASS: registry.hpp declares getBackendName function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: registry.hpp should declare getBackendName function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: registry.hpp should declare getBackends function
if grep -q "CV_EXPORTS_W std::vector<VideoCaptureAPIs> getBackends();" modules/videoio/include/opencv2/videoio/registry.hpp 2>/dev/null; then
    echo "PASS: registry.hpp declares getBackends function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: registry.hpp should declare getBackends function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: registry.hpp should declare getCameraBackends function
if grep -q "CV_EXPORTS_W std::vector<VideoCaptureAPIs> getCameraBackends();" modules/videoio/include/opencv2/videoio/registry.hpp 2>/dev/null; then
    echo "PASS: registry.hpp declares getCameraBackends function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: registry.hpp should declare getCameraBackends function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: registry.hpp should declare getStreamBackends function
if grep -q "CV_EXPORTS_W std::vector<VideoCaptureAPIs> getStreamBackends();" modules/videoio/include/opencv2/videoio/registry.hpp 2>/dev/null; then
    echo "PASS: registry.hpp declares getStreamBackends function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: registry.hpp should declare getStreamBackends function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: registry.hpp should declare getWriterBackends function
if grep -q "CV_EXPORTS_W std::vector<VideoCaptureAPIs> getWriterBackends();" modules/videoio/include/opencv2/videoio/registry.hpp 2>/dev/null; then
    echo "PASS: registry.hpp declares getWriterBackends function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: registry.hpp should declare getWriterBackends function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: videoio.hpp should reference videoio_registry defgroup
if grep -q "@defgroup videoio_registry Query I/O API backends registry" modules/videoio/include/opencv2/videoio.hpp 2>/dev/null; then
    echo "PASS: videoio.hpp references videoio_registry defgroup"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: videoio.hpp should reference videoio_registry defgroup" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: videoio_registry.cpp should include registry.hpp
if grep -q '#include "opencv2/videoio/registry.hpp"' modules/videoio/src/videoio_registry.cpp 2>/dev/null; then
    echo "PASS: videoio_registry.cpp includes registry.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: videoio_registry.cpp should include registry.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: videoio_registry.cpp should implement getBackendName
if grep -q "cv::String getBackendName(VideoCaptureAPIs api)" modules/videoio/src/videoio_registry.cpp 2>/dev/null; then
    echo "PASS: videoio_registry.cpp implements getBackendName"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: videoio_registry.cpp should implement getBackendName" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: videoio_registry.cpp should implement getBackends
if grep -q "std::vector<VideoCaptureAPIs> getBackends()" modules/videoio/src/videoio_registry.cpp 2>/dev/null; then
    echo "PASS: videoio_registry.cpp implements getBackends"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: videoio_registry.cpp should implement getBackends" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: videoio_registry.cpp should implement getCameraBackends
if grep -q "std::vector<VideoCaptureAPIs> getCameraBackends()" modules/videoio/src/videoio_registry.cpp 2>/dev/null; then
    echo "PASS: videoio_registry.cpp implements getCameraBackends"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: videoio_registry.cpp should implement getCameraBackends" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: videoio_registry.cpp should implement getStreamBackends
if grep -q "std::vector<VideoCaptureAPIs> getStreamBackends()" modules/videoio/src/videoio_registry.cpp 2>/dev/null; then
    echo "PASS: videoio_registry.cpp implements getStreamBackends"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: videoio_registry.cpp should implement getStreamBackends" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: videoio_registry.cpp should implement getWriterBackends
if grep -q "std::vector<VideoCaptureAPIs> getWriterBackends()" modules/videoio/src/videoio_registry.cpp 2>/dev/null; then
    echo "PASS: videoio_registry.cpp implements getWriterBackends"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: videoio_registry.cpp should implement getWriterBackends" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: VideoBackendRegistry should have getEnabledBackends method
if grep -q "inline std::vector<VideoBackendInfo> getEnabledBackends() const { return enabledBackends; }" modules/videoio/src/videoio_registry.cpp 2>/dev/null; then
    echo "PASS: VideoBackendRegistry has getEnabledBackends method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: VideoBackendRegistry should have getEnabledBackends method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: Python test file should exist
if [ -f "modules/python/test/test_videoio.py" ]; then
    echo "PASS: Python test file exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Python test file should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: Python test should use videoio_registry.getBackendName
if grep -q "cv.videoio_registry.getBackendName" modules/python/test/test_videoio.py 2>/dev/null; then
    echo "PASS: Python test uses videoio_registry.getBackendName"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Python test should use videoio_registry.getBackendName" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 17: Python test should use videoio_registry.getBackends
if grep -q "cv.videoio_registry.getBackends()" modules/python/test/test_videoio.py 2>/dev/null; then
    echo "PASS: Python test uses videoio_registry.getBackends"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Python test should use videoio_registry.getBackends" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 18: pyopencv_videoio.hpp should exist
if [ -f "modules/videoio/misc/python/pyopencv_videoio.hpp" ]; then
    echo "PASS: pyopencv_videoio.hpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_videoio.hpp should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 19: pyopencv_videoio.hpp should define vector_VideoCaptureAPIs
if grep -q "typedef std::vector<VideoCaptureAPIs> vector_VideoCaptureAPIs;" modules/videoio/misc/python/pyopencv_videoio.hpp 2>/dev/null; then
    echo "PASS: pyopencv_videoio.hpp defines vector_VideoCaptureAPIs"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_videoio.hpp should define vector_VideoCaptureAPIs" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 20: pyopencv_videoio.hpp should define pyopencv_to for VideoCaptureAPIs
if grep -q "bool pyopencv_to(PyObject \*o, cv::VideoCaptureAPIs &v, const char \*name)" modules/videoio/misc/python/pyopencv_videoio.hpp 2>/dev/null; then
    echo "PASS: pyopencv_videoio.hpp defines pyopencv_to for VideoCaptureAPIs"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: pyopencv_videoio.hpp should define pyopencv_to for VideoCaptureAPIs" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 21: test_precomp.hpp should include registry.hpp
if grep -q '#include "opencv2/videoio/registry.hpp"' modules/videoio/test/test_precomp.hpp 2>/dev/null; then
    echo "PASS: test_precomp.hpp includes registry.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_precomp.hpp should include registry.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 22: test_precomp.hpp should have operator<< for VideoCaptureAPIs using getBackendName
if grep -q "cv::videoio_registry::getBackendName(api)" modules/videoio/test/test_precomp.hpp 2>/dev/null; then
    echo "PASS: test_precomp.hpp has operator<< using getBackendName"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_precomp.hpp should have operator<< using getBackendName" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 23: test_precomp.hpp should have isBackendAvailable function
if grep -q "static inline bool isBackendAvailable(cv::VideoCaptureAPIs api, const std::vector<cv::VideoCaptureAPIs>& api_list)" modules/videoio/test/test_precomp.hpp 2>/dev/null; then
    echo "PASS: test_precomp.hpp has isBackendAvailable function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_precomp.hpp should have isBackendAvailable function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 24: test_video_io.cpp should use isBackendAvailable with getStreamBackends
if grep -q "isBackendAvailable(apiPref, cv::videoio_registry::getStreamBackends())" modules/videoio/test/test_video_io.cpp 2>/dev/null; then
    echo "PASS: test_video_io.cpp uses isBackendAvailable with getStreamBackends"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_video_io.cpp should use isBackendAvailable with getStreamBackends" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 25: test_video_io.cpp should use VideoCaptureAPIs type (not VideoCaptureAPI wrapper)
if grep -q "VideoCaptureAPIs apiPref;" modules/videoio/test/test_video_io.cpp 2>/dev/null; then
    echo "PASS: test_video_io.cpp uses VideoCaptureAPIs type"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_video_io.cpp should use VideoCaptureAPIs type" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 26: test_video_io.cpp should use getBackendName in skip message
if grep -q "cv::videoio_registry::getBackendName(apiPref)" modules/videoio/test/test_video_io.cpp 2>/dev/null; then
    echo "PASS: test_video_io.cpp uses getBackendName in messages"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_video_io.cpp should use getBackendName in messages" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 27: test_video_io.cpp Backend_Type_Params should use VideoCaptureAPIs
if grep -q "typedef tuple<string, VideoCaptureAPIs> Backend_Type_Params;" modules/videoio/test/test_video_io.cpp 2>/dev/null; then
    echo "PASS: test_video_io.cpp Backend_Type_Params uses VideoCaptureAPIs"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_video_io.cpp Backend_Type_Params should use VideoCaptureAPIs" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 28: test_video_io.cpp should NOT have VideoCaptureAPI wrapper struct
if ! grep -q "struct VideoCaptureAPI" modules/videoio/test/test_video_io.cpp 2>/dev/null; then
    echo "PASS: test_video_io.cpp does not have VideoCaptureAPI wrapper struct"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_video_io.cpp should not have VideoCaptureAPI wrapper struct" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 29: cv2.cpp should include pyopencv_custom_headers.h in correct position
if grep -B5 -A5 "pyopencv_generated_types.h" modules/python/src2/cv2.cpp 2>/dev/null | grep -q "pyopencv_custom_headers.h"; then
    echo "PASS: cv2.cpp includes pyopencv_custom_headers.h before generated files"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: cv2.cpp should include pyopencv_custom_headers.h before generated files" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 30: Ext_Fourcc_PSNR should use VideoCaptureAPIs
if grep -q "VideoCaptureAPIs api;" modules/videoio/test/test_video_io.cpp 2>/dev/null; then
    echo "PASS: Ext_Fourcc_PSNR uses VideoCaptureAPIs"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Ext_Fourcc_PSNR should use VideoCaptureAPIs" >&2
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

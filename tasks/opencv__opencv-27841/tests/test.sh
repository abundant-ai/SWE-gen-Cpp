#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/videoio/test"
cp "/tests/modules/videoio/test/test_camera.cpp" "modules/videoio/test/test_camera.cpp"
mkdir -p "modules/videoio/test"
cp "/tests/modules/videoio/test/test_v4l2.cpp" "modules/videoio/test/test_v4l2.cpp"

# Check if FFMPEG camera capture support exists in the source code
# In BASE state (buggy), cvCreateCameraCapture_FFMPEG_proxy function is removed
# In HEAD state (fixed), the function exists
if grep -q "cvCreateCameraCapture_FFMPEG_proxy" modules/videoio/src/cap_interface.hpp; then
    echo "PASS: FFMPEG camera capture support found in source code (fixed version)"
    test_status=0
else
    echo "FAIL: FFMPEG camera capture support missing from source code (buggy version)" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

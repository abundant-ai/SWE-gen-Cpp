#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"

checks_passed=0
checks_failed=0

# PR #11923: Fix DNN build with external Protobuf 3.x

# Check 1: CMakeLists.txt should define OPENCV_DNN_EXTERNAL_PROTOBUF when NOT BUILD_PROTOBUF
if grep -q 'if(NOT BUILD_PROTOBUF)' modules/dnn/CMakeLists.txt 2>/dev/null && \
   grep -q 'add_definitions(-DOPENCV_DNN_EXTERNAL_PROTOBUF=1)' modules/dnn/CMakeLists.txt 2>/dev/null; then
    echo "PASS: CMakeLists.txt defines OPENCV_DNN_EXTERNAL_PROTOBUF for external protobuf"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt should define OPENCV_DNN_EXTERNAL_PROTOBUF when NOT BUILD_PROTOBUF" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: caffe_io.cpp should use conditional compilation for TextFormat::Parser
if grep -q '#ifndef OPENCV_DNN_EXTERNAL_PROTOBUF' modules/dnn/src/caffe/caffe_io.cpp 2>/dev/null && \
   grep -q 'google::protobuf::TextFormat::Parser(true)\.Parse' modules/dnn/src/caffe/caffe_io.cpp 2>/dev/null && \
   grep -q '#else' modules/dnn/src/caffe/caffe_io.cpp 2>/dev/null && \
   grep -q 'google::protobuf::TextFormat::Parser()\.Parse' modules/dnn/src/caffe/caffe_io.cpp 2>/dev/null; then
    echo "PASS: caffe_io.cpp uses conditional compilation for Protobuf 3.x compatibility"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: caffe_io.cpp should handle both internal and external Protobuf APIs" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: test_layers.cpp Interp test should be conditionally disabled for external protobuf
if grep -q '#ifndef OPENCV_DNN_EXTERNAL_PROTOBUF' modules/dnn/test/test_layers.cpp 2>/dev/null && \
   grep -q 'TEST_P(Test_Caffe_layers, Interp)' modules/dnn/test/test_layers.cpp 2>/dev/null && \
   grep -q '#else' modules/dnn/test/test_layers.cpp 2>/dev/null && \
   grep -q 'TEST_P(Test_Caffe_layers, DISABLED_Interp)' modules/dnn/test/test_layers.cpp 2>/dev/null; then
    echo "PASS: test_layers.cpp conditionally disables Interp test for external protobuf"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_layers.cpp should conditionally handle Interp test based on protobuf source" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: ReadProtoFromTextFile function should exist in caffe_io.cpp
if grep -q 'bool ReadProtoFromTextFile' modules/dnn/src/caffe/caffe_io.cpp 2>/dev/null; then
    echo "PASS: ReadProtoFromTextFile function is present"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: ReadProtoFromTextFile function should be defined" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: The fix should preserve the parsing behavior (Parser constructor argument)
if grep -A5 'ReadProtoFromTextFile' modules/dnn/src/caffe/caffe_io.cpp | grep -q 'Parser(true)'; then
    echo "PASS: Parser(true) is used for internal protobuf (preserving original behavior)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Parser(true) should be used for OpenCV's internal protobuf build" >&2
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

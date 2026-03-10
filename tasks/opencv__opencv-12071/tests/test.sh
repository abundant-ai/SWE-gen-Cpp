#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_onnx_importer.cpp" "modules/dnn/test/test_onnx_importer.cpp"

checks_passed=0
checks_failed=0

# PR #12071: ONNX model importing support for DNN module

# Check 1: CMakeLists.txt should include opencv-onnx.proto in proto files
if grep -q 'file(GLOB proto_files.*opencv-onnx.proto' modules/dnn/CMakeLists.txt 2>/dev/null; then
    echo "PASS: CMakeLists.txt includes opencv-onnx.proto"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt should include opencv-onnx.proto" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: dnn.hpp should declare readNetFromONNX function
if grep -q 'CV_EXPORTS_W Net readNetFromONNX' modules/dnn/include/opencv2/dnn/dnn.hpp 2>/dev/null; then
    echo "PASS: dnn.hpp declares readNetFromONNX function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp should declare readNetFromONNX function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: dnn.hpp should declare readTensorFromONNX function
if grep -q 'CV_EXPORTS_W Mat readTensorFromONNX' modules/dnn/include/opencv2/dnn/dnn.hpp 2>/dev/null; then
    echo "PASS: dnn.hpp declares readTensorFromONNX function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp should declare readTensorFromONNX function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: dict.hpp should declare erase method
if grep -q 'void erase(const String &key)' modules/dnn/include/opencv2/dnn/dict.hpp 2>/dev/null; then
    echo "PASS: dict.hpp declares erase method"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dict.hpp should declare erase method" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: dnn.inl.hpp should implement Dict::erase
if grep -q 'inline void Dict::erase' modules/dnn/include/opencv2/dnn/dnn.inl.hpp 2>/dev/null; then
    echo "PASS: dnn.inl.hpp implements Dict::erase"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.inl.hpp should implement Dict::erase" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: opencv-onnx.proto file should exist
if [ -f modules/dnn/src/onnx/opencv-onnx.proto ]; then
    echo "PASS: opencv-onnx.proto file exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: opencv-onnx.proto file should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: opencv-onnx.pb.cc file should exist
if [ -f modules/dnn/misc/onnx/opencv-onnx.pb.cc ]; then
    echo "PASS: opencv-onnx.pb.cc file exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: opencv-onnx.pb.cc file should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: opencv-onnx.pb.h file should exist
if [ -f modules/dnn/misc/onnx/opencv-onnx.pb.h ]; then
    echo "PASS: opencv-onnx.pb.h file exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: opencv-onnx.pb.h file should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: onnx_importer.cpp should exist
if [ -f modules/dnn/src/onnx/onnx_importer.cpp ]; then
    echo "PASS: onnx_importer.cpp file exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_importer.cpp file should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: onnx_importer.cpp should implement readNetFromONNX
if grep -q 'Net readNetFromONNX(const String& onnxFile)' modules/dnn/src/onnx/onnx_importer.cpp 2>/dev/null; then
    echo "PASS: onnx_importer.cpp implements readNetFromONNX"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_importer.cpp should implement readNetFromONNX" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: onnx_importer.cpp should implement readTensorFromONNX
if grep -q 'Mat readTensorFromONNX(const String& path)' modules/dnn/src/onnx/onnx_importer.cpp 2>/dev/null; then
    echo "PASS: onnx_importer.cpp implements readTensorFromONNX"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: onnx_importer.cpp should implement readTensorFromONNX" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: dnn.cpp should call readNetFromONNX for .onnx files
if grep -q 'return readNetFromONNX(model)' modules/dnn/src/dnn.cpp 2>/dev/null; then
    echo "PASS: dnn.cpp calls readNetFromONNX for .onnx files"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp should call readNetFromONNX for .onnx files" >&2
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

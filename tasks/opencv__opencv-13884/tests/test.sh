#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_backends.cpp" "modules/dnn/test/test_backends.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_common.hpp" "modules/dnn/test/test_common.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_halide_layers.cpp" "modules/dnn/test/test_halide_layers.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_layers.cpp" "modules/dnn/test/test_layers.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_tf_importer.cpp" "modules/dnn/test/test_tf_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_torch_importer.cpp" "modules/dnn/test/test_torch_importer.cpp"

checks_passed=0
checks_failed=0

# PR #13884 removes support for older Inference Engine releases (2018R1 and 2018R2)
# by removing version checks and macro definitions - makes R3 the minimal version
# HEAD (ed710eaa1c8dadf99247b94a3558ed9883af591e): R3 minimal, no R1/R2 support checks
# BASE (after bug.patch): Has R1/R2 support with version checks
# FIXED (after fix.patch): R3 minimal, no R1/R2 support checks (matches HEAD)

# Check 1: INF_ENGINE_RELEASE_2018R1 macro should NOT be defined (fixed version)
if ! grep -q '#define INF_ENGINE_RELEASE_2018R1 2018010000' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: INF_ENGINE_RELEASE_2018R1 macro removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: INF_ENGINE_RELEASE_2018R1 macro still defined (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: INF_ENGINE_RELEASE_2018R2 macro should NOT be defined (fixed version)
if ! grep -q '#define INF_ENGINE_RELEASE_2018R2 2018020000' modules/dnn/src/op_inf_engine.hpp; then
    echo "PASS: INF_ENGINE_RELEASE_2018R2 macro removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: INF_ENGINE_RELEASE_2018R2 macro still defined (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: AddExtension should NOT be guarded with version check (fixed version)
if ! grep -B 1 'InferenceEngine::StatusCode InfEngineBackendNet::AddExtension' modules/dnn/src/op_inf_engine.cpp | grep -q '#if INF_ENGINE_VER_MAJOR_GT(INF_ENGINE_RELEASE_2018R2)'; then
    echo "PASS: AddExtension version guard removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: AddExtension still has version guard (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: reshape should NOT have #endif after it (fixed version)
if ! grep -A 3 'InferenceEngine::StatusCode InfEngineBackendNet::reshape' modules/dnn/src/op_inf_engine.cpp | grep -q '#endif'; then
    echo "PASS: reshape #endif removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: reshape still has #endif (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: convolution_layer.cpp should NOT have version check for group != 1 (fixed version)
if ! grep -A 4 'if (group != 1)' modules/dnn/src/layers/convolution_layer.cpp | grep -q '#if INF_ENGINE_VER_MAJOR_GE(INF_ENGINE_RELEASE_2018R3)'; then
    echo "PASS: group != 1 version guard removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: group != 1 still has version guard (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: convolution_layer.cpp should NOT have return false after group check (fixed version)
if ! grep -A 5 'if (group != 1)' modules/dnn/src/layers/convolution_layer.cpp | grep -q 'return false'; then
    echo "PASS: group != 1 return false removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: group != 1 still has return false (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_backends.cpp should NOT have R1/R2 check in OpenFace test (fixed version)
if grep -A 10 'TEST_P(DNNTestNetwork, OpenFace)' modules/dnn/test/test_backends.cpp | grep -q '#if INF_ENGINE_RELEASE == 2018050000'; then
    echo "PASS: test_backends.cpp OpenFace test R1/R2 check removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_backends.cpp OpenFace test still has R1/R2 check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_common.hpp should NOT have R1/R2 batch size handling (fixed version)
if ! grep -q '#if defined(INF_ENGINE_RELEASE) && INF_ENGINE_RELEASE < 2018030000' modules/dnn/test/test_common.hpp; then
    echo "PASS: test_common.hpp R1/R2 batch size check removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_common.hpp still has R1/R2 batch size check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: test_halide_layers.cpp should NOT have R1/R2 check for Convolution test (fixed version)
if ! grep -A 5 'Target targetId = get<1>(get<7>(GetParam()));' modules/dnn/test/test_halide_layers.cpp | grep -q '#if defined(INF_ENGINE_RELEASE) && INF_ENGINE_RELEASE < 2018030000'; then
    echo "PASS: test_halide_layers.cpp Convolution R1/R2 check removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_halide_layers.cpp Convolution still has R1/R2 check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: test_layers.cpp should NOT have R1/R2 check for BatchNorm test (fixed version)
if ! grep -A 3 'TEST_P(Test_Caffe_layers, BatchNorm)' modules/dnn/test/test_layers.cpp | grep -q '#if defined(INF_ENGINE_RELEASE) && INF_ENGINE_RELEASE < 2018030000'; then
    echo "PASS: test_layers.cpp BatchNorm R1/R2 check removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_layers.cpp BatchNorm still has R1/R2 check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: test_tf_importer.cpp should NOT have R1/R2 check for pad_and_concat test (fixed version)
if ! grep -A 3 'TEST_P(Test_TensorFlow_layers, pad_and_concat)' modules/dnn/test/test_tf_importer.cpp | grep -q '#if defined(INF_ENGINE_RELEASE) && INF_ENGINE_RELEASE < 2018030000'; then
    echo "PASS: test_tf_importer.cpp pad_and_concat R1/R2 check removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp pad_and_concat still has R1/R2 check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: test_tf_importer.cpp should NOT have fp16_pad_and_concat test with R1/R2 check (fixed version)
if ! grep -A 5 'TEST_P(Test_TensorFlow_layers, fp16_pad_and_concat)' modules/dnn/test/test_tf_importer.cpp 2>/dev/null | grep -q '#if defined(INF_ENGINE_RELEASE) && INF_ENGINE_RELEASE < 2018030000'; then
    echo "PASS: test_tf_importer.cpp fp16_pad_and_concat R1/R2 check removed or test removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_tf_importer.cpp fp16_pad_and_concat still has R1/R2 check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: test_torch_importer.cpp should NOT have R1/R2 check for OpenFace_accuracy (fixed version)
if grep -A 10 'TEST_P(Test_Torch_nets, OpenFace_accuracy)' modules/dnn/test/test_torch_importer.cpp | grep -q '#if defined(INF_ENGINE_RELEASE) && INF_ENGINE_RELEASE == 2018050000'; then
    echo "PASS: test_torch_importer.cpp OpenFace_accuracy R1/R2 check removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_torch_importer.cpp OpenFace_accuracy still has R1/R2 check (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: perf_net.cpp should NOT have OpenPose_pose_coco test (fixed version - removed in this PR)
if ! grep -q 'PERF_TEST_P_(DNNTestNetwork, OpenPose_pose_coco)' modules/dnn/perf/perf_net.cpp; then
    echo "PASS: perf_net.cpp OpenPose_pose_coco test removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_net.cpp still has OpenPose_pose_coco test (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: perf_net.cpp should NOT have OpenPose_pose_mpi test (fixed version - removed in this PR)
if ! grep -q 'PERF_TEST_P_(DNNTestNetwork, OpenPose_pose_mpi)' modules/dnn/perf/perf_net.cpp; then
    echo "PASS: perf_net.cpp OpenPose_pose_mpi test removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_net.cpp still has OpenPose_pose_mpi test (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 16: perf_net.cpp EAST_text_detection should NOT have R1/R2 check for MYRIAD (fixed version)
if ! grep -A 5 'PERF_TEST_P_(DNNTestNetwork, EAST_text_detection)' modules/dnn/perf/perf_net.cpp | grep -q '#if defined(INF_ENGINE_RELEASE) && INF_ENGINE_RELEASE < 2018030000'; then
    echo "PASS: perf_net.cpp EAST_text_detection R1/R2 check removed (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: perf_net.cpp EAST_text_detection still has R1/R2 check (buggy version)" >&2
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

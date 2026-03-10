#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_torch_importer.cpp" "modules/dnn/test/test_torch_importer.cpp"

checks_passed=0
checks_failed=0

# PR #13497 adds an `evaluate` parameter to readNetFromTorch()
# HEAD (840c892abd8eb1cacc71a3f38330483ae38a02d9): Fixed version with evaluate parameter
# BASE (after bug.patch): Buggy version without evaluate parameter
# FIXED (after fix.patch): Fixed version (matches HEAD)

# Check 1: dnn.hpp should have evaluate parameter in readNetFromTorch declaration
if grep -q 'CV_EXPORTS_W Net readNetFromTorch(const String &model, bool isBinary = true, bool evaluate = true);' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: dnn.hpp has readNetFromTorch with evaluate parameter (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp missing evaluate parameter in readNetFromTorch (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: dnn.hpp should have documentation for evaluate parameter
if grep -q '@param evaluate specifies testing phase of network' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: dnn.hpp has documentation for evaluate parameter (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp missing documentation for evaluate parameter (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: torch_importer.cpp should have testPhase member variable
if grep -q 'bool testPhase;' modules/dnn/src/torch/torch_importer.cpp; then
    echo "PASS: torch_importer.cpp has testPhase member variable (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: torch_importer.cpp missing testPhase member variable (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: torch_importer.cpp TorchImporter constructor should accept evaluate parameter
if grep -q 'TorchImporter(String filename, bool isBinary, bool evaluate)' modules/dnn/src/torch/torch_importer.cpp; then
    echo "PASS: torch_importer.cpp TorchImporter constructor accepts evaluate parameter (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: torch_importer.cpp TorchImporter constructor missing evaluate parameter (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: torch_importer.cpp should initialize testPhase from evaluate parameter
if grep -q 'testPhase = evaluate;' modules/dnn/src/torch/torch_importer.cpp; then
    echo "PASS: torch_importer.cpp initializes testPhase from evaluate (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: torch_importer.cpp missing testPhase initialization (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: torch_importer.cpp should use trainPhase and testPhase in BatchNorm logic
if grep -q 'bool trainPhase = scalarParams.get<bool>("train", false);' modules/dnn/src/torch/torch_importer.cpp && \
   grep -q 'if (nnName == "InstanceNormalization" || (trainPhase && !testPhase))' modules/dnn/src/torch/torch_importer.cpp; then
    echo "PASS: torch_importer.cpp uses trainPhase && !testPhase for BatchNorm logic (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: torch_importer.cpp missing trainPhase/testPhase logic (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: readNetFromTorch function should accept and pass evaluate parameter
if grep -q 'Net readNetFromTorch(const String &model, bool isBinary, bool evaluate)' modules/dnn/src/torch/torch_importer.cpp && \
   grep -q 'TorchImporter importer(model, isBinary, evaluate);' modules/dnn/src/torch/torch_importer.cpp; then
    echo "PASS: readNetFromTorch accepts and passes evaluate parameter (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: readNetFromTorch missing evaluate parameter handling (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: readTorchBlob should pass true for evaluate parameter
if grep -q 'TorchImporter importer(filename, isBinary, true);' modules/dnn/src/torch/torch_importer.cpp; then
    echo "PASS: readTorchBlob passes true for evaluate (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: readTorchBlob not passing evaluate parameter correctly (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: Experimental namespace version should be v11 (not v10)
if grep -q 'namespace experimental_dnn_34_v11' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: dnn.hpp uses experimental_dnn_34_v11 namespace (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp using wrong namespace version (buggy version)" >&2
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

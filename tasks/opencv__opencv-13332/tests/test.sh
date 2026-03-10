#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_backends.cpp" "modules/dnn/test/test_backends.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_caffe_importer.cpp" "modules/dnn/test/test_caffe_importer.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_common.hpp" "modules/dnn/test/test_common.hpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_googlenet.cpp" "modules/dnn/test/test_googlenet.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_ie_models.cpp" "modules/dnn/test/test_ie_models.cpp"
mkdir -p "modules/dnn/test"
cp "/tests/modules/dnn/test/test_misc.cpp" "modules/dnn/test/test_misc.cpp"

checks_passed=0
checks_failed=0

# PR #13332: The PR removes getAvailableBackends() and getAvailableTargets() API
# For harbor testing:
# - HEAD (dad7b6aeca2461973f5a342b821fb0fe2865e884): API functions exist (fixed version)
# - BASE (after bug.patch): API functions removed (buggy version)
# - FIXED (after fix.patch): API functions exist again (back to HEAD)

# Check 1: dnn.hpp should have getAvailableBackends() declaration
if grep -q 'CV_EXPORTS std::vector< std::pair<Backend, Target> > getAvailableBackends();' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: dnn.hpp has getAvailableBackends() declaration (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp missing getAvailableBackends() declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: dnn.hpp should have getAvailableTargets() declaration
if grep -q 'CV_EXPORTS std::vector<Target> getAvailableTargets(Backend be);' modules/dnn/include/opencv2/dnn/dnn.hpp; then
    echo "PASS: dnn.hpp has getAvailableTargets() declaration (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.hpp missing getAvailableTargets() declaration (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: dnn.cpp should have BackendRegistry class
if grep -q 'class BackendRegistry' modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp has BackendRegistry class (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing BackendRegistry class (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: dnn.cpp should implement getAvailableBackends()
if grep -q 'std::vector< std::pair<Backend, Target> > getAvailableBackends()' modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp implements getAvailableBackends() (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing getAvailableBackends() implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: dnn.cpp should implement getAvailableTargets()
if grep -q 'std::vector<Target> getAvailableTargets(Backend be)' modules/dnn/src/dnn.cpp; then
    echo "PASS: dnn.cpp implements getAvailableTargets() (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: dnn.cpp missing getAvailableTargets() implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: test_caffe_importer.cpp should use getAvailableTargets() (old API, fixed version)
if grep -q 'getAvailableTargets(DNN_BACKEND_OPENCV)' modules/dnn/test/test_caffe_importer.cpp; then
    echo "PASS: test_caffe_importer.cpp uses getAvailableTargets() (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_caffe_importer.cpp not using getAvailableTargets() (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: test_googlenet.cpp should use getAvailableTargets() (old API, fixed version)
if grep -q 'getAvailableTargets(DNN_BACKEND_OPENCV)' modules/dnn/test/test_googlenet.cpp; then
    echo "PASS: test_googlenet.cpp uses getAvailableTargets() (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_googlenet.cpp not using getAvailableTargets() (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_backends.cpp should use dnnBackendsAndTargets() without parameters (old API, fixed version)
if grep -q 'INSTANTIATE_TEST_CASE_P(/\*nothing\*/,\s*DNNTestNetwork,\s*dnnBackendsAndTargets());' modules/dnn/test/test_backends.cpp; then
    echo "PASS: test_backends.cpp uses dnnBackendsAndTargets() without parameters (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_backends.cpp not using dnnBackendsAndTargets() correctly (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: test_ie_models.cpp should use getAvailableTargets() (old API, fixed version)
if grep -q 'getAvailableTargets(DNN_BACKEND_INFERENCE_ENGINE)' modules/dnn/test/test_ie_models.cpp; then
    echo "PASS: test_ie_models.cpp uses getAvailableTargets() (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_ie_models.cpp not using getAvailableTargets() (buggy version)" >&2
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

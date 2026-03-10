#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/gapi/test"
cp "/tests/modules/gapi/test/gapi_async_test.cpp" "modules/gapi/test/gapi_async_test.cpp"

checks_passed=0
checks_failed=0

# Check 1: gcompiled_async.hpp should have documentation comment for async functions (fixed version)
if grep -q "//These functions asynchronously (i.e. probably on a separate thread of execution) call operator() member function of their first argument with copies of rest of arguments (except callback) passed in." modules/gapi/include/opencv2/gapi/gcompiled_async.hpp; then
    echo "PASS: gcompiled_async.hpp has documentation comment for async functions (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gcompiled_async.hpp missing documentation comment (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: gcompiled_async.hpp should have comment explaining std::future include (fixed version)
if grep -q "#include <future>           //for std::future" modules/gapi/include/opencv2/gapi/gcompiled_async.hpp; then
    echo "PASS: gcompiled_async.hpp has comment explaining std::future include (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gcompiled_async.hpp missing comment for std::future include (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: gcomputation_async.hpp should have documentation comment for async_apply functions (fixed version)
if grep -q "//These functions asynchronously (i.e. probably on a separate thread of execution) call apply member function of their first argument with copies of rest of arguments (except callback) passed in." modules/gapi/include/opencv2/gapi/gcomputation_async.hpp; then
    echo "PASS: gcomputation_async.hpp has documentation comment for async_apply functions (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gcomputation_async.hpp missing documentation comment (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: gasync.cpp should use "guarding lock" not "protecting lock" (fixed version)
if grep -q "//move the whole queue into local instance in order to minimize time the guarding lock is held" modules/gapi/src/executor/gasync.cpp; then
    echo "PASS: gasync.cpp uses correct terminology 'guarding lock' (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gasync.cpp has incorrect terminology 'protecting lock' (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: gasync.cpp should have correct grammar "which is processed" not "which is when processed" (fixed version)
if grep -q "//These functors are then serialized into single queue, which is processed by a devoted background thread." modules/gapi/src/executor/gasync.cpp; then
    echo "PASS: gasync.cpp has correct grammar 'which is processed' (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gasync.cpp has incorrect grammar 'which is when processed' (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: gasync.cpp should NOT have the commented-out chrono include (fixed version removes it)
if grep -q "//#include <chrono>" modules/gapi/src/executor/gasync.cpp; then
    echo "FAIL: gasync.cpp still has commented-out chrono include (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
else
    echo "PASS: gasync.cpp does not have commented-out chrono include (fixed version)"
    checks_passed=$((checks_passed + 1))
fi

# Check 7: gapi_async_test.cpp should have explanation comments about test mixins (fixed version)
if grep -q "//Main idea behind these tests is to have the same test script that is parameterized in order to test all setups" modules/gapi/test/gapi_async_test.cpp; then
    echo "PASS: gapi_async_test.cpp has test mixin explanation comments (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gapi_async_test.cpp missing test mixin explanation comments (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: gapi_async_test.cpp should have comment explaining CallBack mixin (fixed version)
if grep -q "//Test Mixin, hiding details of callback based notification" modules/gapi/test/gapi_async_test.cpp; then
    echo "PASS: gapi_async_test.cpp has CallBack mixin comment (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gapi_async_test.cpp missing CallBack mixin comment (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: gapi_async_test.cpp should use 'out_sc' not 'out' for output scalar (fixed version)
if grep -q "cv::Scalar out_sc;" modules/gapi/test/gapi_async_test.cpp; then
    echo "PASS: gapi_async_test.cpp uses 'out_sc' for output scalar (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gapi_async_test.cpp uses 'out' instead of 'out_sc' (buggy version)" >&2
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

#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/gapi/test"
cp "/tests/modules/gapi/test/gapi_planar_test.cpp" "modules/gapi/test/gapi_planar_test.cpp"
mkdir -p "modules/gapi/test/internal"
cp "/tests/modules/gapi/test/internal/gapi_int_garg_test.cpp" "modules/gapi/test/internal/gapi_int_garg_test.cpp"

checks_passed=0
checks_failed=0

# Check 1: gmat.hpp should have GMatP class (fixed version)
if grep -q 'class GAPI_EXPORTS GMatP : public GMat' modules/gapi/include/opencv2/gapi/gmat.hpp; then
    echo "PASS: gmat.hpp has GMatP class (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gmat.hpp missing GMatP class (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: gtype_traits.hpp should have GMatP traits with GMATP kind (fixed version)
if grep -q 'ArgKind::GMATP' modules/gapi/include/opencv2/gapi/gtype_traits.hpp && \
   grep -q 'struct GTypeTraits<cv::GMatP>' modules/gapi/include/opencv2/gapi/gtype_traits.hpp; then
    echo "PASS: gtype_traits.hpp has GMatP type traits (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gtype_traits.hpp missing GMatP type traits (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: gcall.hpp should have yieldP method (fixed version)
if grep -q 'GMatP   yieldP' modules/gapi/include/opencv2/gapi/gcall.hpp; then
    echo "PASS: gcall.hpp has yieldP method (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gcall.hpp missing yieldP method (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: gkernel.hpp should have Yield<GMatP> specialization (fixed version)
if grep -q 'struct Yield<cv::GMatP>' modules/gapi/include/opencv2/gapi/gkernel.hpp; then
    echo "PASS: gkernel.hpp has Yield<GMatP> specialization (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gkernel.hpp missing Yield<GMatP> specialization (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: gproto.hpp should include GMatP in variant (fixed version)
if grep -q ', GMatP' modules/gapi/include/opencv2/gapi/gproto.hpp; then
    echo "PASS: gproto.hpp includes GMatP in GProtoArg variant (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gproto.hpp missing GMatP in GProtoArg variant (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: gcpukernel.hpp should have get_in<GMatP> and get_out<GMatP> specializations (fixed version)
if grep -q 'struct get_in<cv::GMatP>' modules/gapi/include/opencv2/gapi/cpu/gcpukernel.hpp && \
   grep -q 'struct get_out<cv::GMatP>' modules/gapi/include/opencv2/gapi/cpu/gcpukernel.hpp; then
    echo "PASS: gcpukernel.hpp has GMatP get_in/get_out specializations (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gcpukernel.hpp missing GMatP get_in/get_out specializations (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: gcall.cpp should implement yieldP method (fixed version)
if grep -q 'cv::GMatP cv::GCall::yieldP' modules/gapi/src/api/gcall.cpp; then
    echo "PASS: gcall.cpp implements yieldP method (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gcall.cpp missing yieldP implementation (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: gproto.cpp should handle GMatP in origin_of (fixed version)
if grep -q 'case cv::GProtoArg::index_of<cv::GMatP>():' modules/gapi/src/api/gproto.cpp; then
    echo "PASS: gproto.cpp handles GMatP in origin_of (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gproto.cpp not handling GMatP in origin_of (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: gapi_planar_test.cpp should use GMatP in kernel signatures (fixed version)
if grep -q '<GMatP(GMat,Size,int)>' modules/gapi/test/gapi_planar_test.cpp || \
   grep -q '<GMatP(GMatP,Size,int)>' modules/gapi/test/gapi_planar_test.cpp || \
   grep -q '<GMatP(GMat,GMat)>' modules/gapi/test/gapi_planar_test.cpp; then
    echo "PASS: gapi_planar_test.cpp uses GMatP type (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gapi_planar_test.cpp not using GMatP type (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: gapi_int_garg_test.cpp should have GMatP in test types (fixed version)
if grep -q 'Expected<cv::GMatP,' modules/gapi/test/internal/gapi_int_garg_test.cpp; then
    echo "PASS: gapi_int_garg_test.cpp includes GMatP in test types (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gapi_int_garg_test.cpp missing GMatP in test types (buggy version)" >&2
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

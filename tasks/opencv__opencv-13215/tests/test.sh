#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/gapi/test"
cp "/tests/modules/gapi/test/gapi_fluid_test.cpp" "modules/gapi/test/gapi_fluid_test.cpp"

checks_passed=0
checks_failed=0

# PR #13215: The PR adds caching to G-API Fluid backend for performance optimization
# For harbor testing:
# - HEAD (339a57377f43309f9e450d8fbbfcea6a7d661993): Cache structs in View/Buffer, inline accessors (fixed version)
# - BASE (after bug.patch): Cache structs removed, accessors not inline (buggy version)
# - FIXED (after fix.patch): Cache structs added back, inline accessors (back to HEAD)

# Check 1: gfluidbuffer.hpp should include View::Cache struct
if grep -q "struct Cache" modules/gapi/include/opencv2/gapi/fluid/gfluidbuffer.hpp && \
   grep -A 10 "class GAPI_EXPORTS View" modules/gapi/include/opencv2/gapi/fluid/gfluidbuffer.hpp | grep -q "struct Cache"; then
    echo "PASS: gfluidbuffer.hpp includes View::Cache struct (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: gfluidbuffer.hpp missing View::Cache struct (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: View should have m_cache member
if grep -q "const Cache\* m_cache;" modules/gapi/include/opencv2/gapi/fluid/gfluidbuffer.hpp; then
    echo "PASS: View has m_cache member (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: View missing m_cache member (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: Buffer should have Cache struct
if grep -A 50 "class GAPI_EXPORTS Buffer" modules/gapi/include/opencv2/gapi/fluid/gfluidbuffer.hpp | grep -q "struct Cache"; then
    echo "PASS: Buffer has Cache struct (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Buffer missing Cache struct (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: Buffer should have m_cache member
if grep -A 100 "class GAPI_EXPORTS Buffer" modules/gapi/include/opencv2/gapi/fluid/gfluidbuffer.hpp | grep -q "const Cache\* m_cache;"; then
    echo "PASS: Buffer has m_cache member (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Buffer missing m_cache member (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: InLineB should be inline with cache access
if grep -q "const inline uint8_t\* InLineB(int index) const" modules/gapi/include/opencv2/gapi/fluid/gfluidbuffer.hpp && \
   grep -A 3 "const inline uint8_t\* InLineB" modules/gapi/include/opencv2/gapi/fluid/gfluidbuffer.hpp | grep -q "return m_cache->linePtr(index)"; then
    echo "PASS: InLineB is inline with cache access (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: InLineB not inline or missing cache access (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: OutLineB should be inline with cache access
if grep -q "inline uint8_t\* OutLineB(int index = 0)" modules/gapi/include/opencv2/gapi/fluid/gfluidbuffer.hpp && \
   grep -A 3 "inline uint8_t\* OutLineB" modules/gapi/include/opencv2/gapi/fluid/gfluidbuffer.hpp | grep -q "return m_cache->m_linePtrs\[index\]"; then
    echo "PASS: OutLineB is inline with cache access (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OutLineB not inline or missing cache access (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: View::length() should be inline using cache
if grep -q "inline int length() const { return m_cache->m_desc.size.width; }" modules/gapi/include/opencv2/gapi/fluid/gfluidbuffer.hpp; then
    echo "PASS: View::length() is inline using cache (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: View::length() not inline or not using cache (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: View::meta() should be inline using cache
if grep -q "inline const GMatDesc& meta() const { return m_cache->m_desc; }" modules/gapi/include/opencv2/gapi/fluid/gfluidbuffer.hpp; then
    echo "PASS: View::meta() is inline using cache (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: View::meta() not inline or not using cache (buggy version)" >&2
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

#!/bin/bash

cd /app/src

# This PR fixes missing field detection in static reflection deserialization
# In BASE state (after bug.patch), the implementation has incorrect error handling
# The fix should restore proper optional field handling with reset() check

test_status=1

# Check 1: Verify reset() requirement exists in concepts.h for optional_type
if grep -q '{ obj.reset() } noexcept -> std::same_as<void>;' include/simdjson/concepts.h 2>/dev/null; then
    echo "✓ reset() requirement found in optional_type concept"
    test_status=0
else
    echo "✗ reset() requirement missing in optional_type concept - concept is incomplete"
    test_status=1
fi

# Check 2: Verify documentation about missing field handling exists
if grep -q "If a key is missing in the JSON document, an error is generated" doc/basics.md 2>/dev/null; then
    echo "✓ Missing field documentation found in doc/basics.md"
else
    echo "✗ Missing field documentation not found - documentation is incomplete"
    test_status=1
fi

# Check 3: Verify the implementation properly handles optional types (not using generic error handling)
if grep -q 'if constexpr (concepts::optional_type<decltype(out\.\[:mem:\])>)' include/simdjson/generic/ondemand/std_deserialize.h 2>/dev/null; then
    echo "✓ Optional type conditional handling found in deserialization implementation"
else
    echo "✗ Optional type conditional handling missing - implementation uses incorrect generic approach"
    test_status=1
fi

# Check 4: Verify optional fields call reset() on NO_SUCH_FIELD
if grep -q 'out\.\[:mem:\]\.reset()' include/simdjson/generic/ondemand/std_deserialize.h 2>/dev/null; then
    echo "✓ reset() call for optional fields found"
else
    echo "✗ reset() call for optional fields missing - optional fields won't be properly cleared"
    test_status=1
fi

# Check 5: Verify non-optional fields use SIMDJSON_TRY (strict error handling)
# Look for the pattern in the else branch, allowing for flexible whitespace
if grep -Pzo '(?s)if constexpr \(concepts::optional_type.*?\} else \{.*?SIMDJSON_TRY.*?obj\[key\].*?get.*?out\.\[:mem:\]' include/simdjson/generic/ondemand/std_deserialize.h > /dev/null 2>&1; then
    echo "✓ SIMDJSON_TRY for non-optional fields found in else branch"
else
    echo "✗ SIMDJSON_TRY for non-optional fields missing - required fields won't error on missing data"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

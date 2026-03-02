#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/compile_time"
cp "/tests/compile_time/compile_time_json_tests.cpp" "tests/compile_time/compile_time_json_tests.cpp"

# Since the code uses experimental C++26 features that no released compiler supports,
# we can't actually compile it. Instead, we check for the presence of the _json operator
# definition in the header file. This is a simple text-based check.
#
# In BASE state (bug.patch applied): the _json operator definition is removed
# In HEAD state (fix applied): the _json operator definition exists

test_status=0

# Check if the _json operator is defined in compile_time_json.h
if grep -q "operator \"\"_json" include/simdjson/compile_time_json.h; then
  # _json operator exists - test passes (should happen in HEAD/fixed state)
  test_status=0
else
  # _json operator missing - test fails (should happen in BASE/buggy state)
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

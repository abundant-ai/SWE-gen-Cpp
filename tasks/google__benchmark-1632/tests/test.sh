#!/bin/bash

cd /app/src

# Verify the fix: check that string_util.h and string_util.cc have the correct Counter::OneK changes
# Buggy version: std::string HumanReadableNumber(double n, double one_k = 1024.0);
# Fixed version: std::string HumanReadableNumber(double n, Counter::OneK one_k);

# Check string_util.h has the fixed signature
if grep -q 'std::string HumanReadableNumber(double n, Counter::OneK one_k)' src/string_util.h && \
   grep -q '#include "benchmark/benchmark.h"' src/string_util.h && \
   grep -q '#include "benchmark/benchmark.h"' src/string_util.cc && \
   grep -q 'Counter::kIs1024 ? 1024.0 : 1000.0' src/string_util.cc; then
    echo "✓ Fix verified"
    test_status=0
else
    echo "✗ Bug present"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

#!/bin/bash

cd /app/src

export CI=true

# Verify the fix for test executor's results summation is present
# PR #429 fixes by SIMPLIFYING the code:
# 1. InitHarness now takes explicit "name" parameter
# 2. execTestCase takes out channel directly (simpler, not return values)
# 3. Results sent directly to channel (no intermediate error/skip channels)

echo "Checking if InitHarness has explicit name parameter..." >&2
if grep -q 'func InitHarness(cmd string, name string, args \.\.\.string) Harness' tests/harness/executor/harness.go && \
   grep -q 'Name: name,' tests/harness/executor/harness.go; then
    echo "PASS: InitHarness has explicit name parameter" >&2
    has_harness=1
else
    echo "FAIL: InitHarness missing explicit name parameter" >&2
    has_harness=0
fi

echo "Checking if execTestCase takes out channel (simplified)..." >&2
if grep -q 'func execTestCase(tc TestCase, harnesses \[\]Harness, out chan<- TestResult)' tests/harness/executor/worker.go && \
   grep -q 'out <- TestResult{false, false}' tests/harness/executor/worker.go; then
    echo "PASS: execTestCase takes out channel directly" >&2
    has_exec=1
else
    echo "FAIL: execTestCase signature incorrect" >&2
    has_exec=0
fi

echo "Checking if Work function calls execTestCase with channel..." >&2
if grep -q 'execTestCase(tc, harnesses, out)' tests/harness/executor/worker.go; then
    echo "PASS: Work calls execTestCase with out channel" >&2
    has_work=1
else
    echo "FAIL: Work doesn't call execTestCase correctly" >&2
    has_work=0
fi

echo "Checking that complex error/skip channels are NOT present (were removed)..." >&2
if ! grep -q 'errs := make(chan error' tests/harness/executor/worker.go && \
   ! grep -q 'skips := make(chan string' tests/harness/executor/worker.go && \
   ! grep -q 'func execTestCase(tc TestCase, harnesses \[\]Harness) (ok, skip bool)' tests/harness/executor/worker.go; then
    echo "PASS: Complex channel code removed (simplified)" >&2
    has_simple=1
else
    echo "FAIL: Complex channel code still present" >&2
    has_simple=0
fi

# Test passes if all checks pass
if [ $has_harness -eq 1 ] && [ $has_exec -eq 1 ] && [ $has_work -eq 1 ] && [ $has_simple -eq 1 ]; then
    echo "PASS: All PR #429 fixes are present" >&2
    test_status=0
else
    echo "FAIL: Some PR #429 fixes are missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

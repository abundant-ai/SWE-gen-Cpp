#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/testutil.cpp" "tests/testutil.cpp"

# Check if the source files have ZMQ_HAVE_WINDOWS instead of _MSC_VER
# The bug.patch changes ZMQ_HAVE_WINDOWS to _MSC_VER in multiple files
# Oracle will apply fix.patch to revert them back to ZMQ_HAVE_WINDOWS
# NOP won't apply the fix, so source files (not test files) will still have _MSC_VER

# Check src/ipc_address.hpp - this file is NOT copied from /tests, so it shows the actual state
if grep -q "#if defined ZMQ_HAVE_WINDOWS" src/ipc_address.hpp && \
   grep -q "#if defined ZMQ_HAVE_WINDOWS" src/ipc_connecter.cpp && \
   grep -q "#ifdef ZMQ_HAVE_WINDOWS" src/ipc_listener.cpp; then
  # All source files have ZMQ_HAVE_WINDOWS - fix was applied
  test_status=0
else
  # Source files still have _MSC_VER - fix wasn't applied
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

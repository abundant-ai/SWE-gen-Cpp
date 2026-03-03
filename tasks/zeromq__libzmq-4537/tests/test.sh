#!/bin/bash

cd /app/src

# The fix adds the RELICENSE/chachoi.md file
# Check that the file exists
test_status=1

if [ -f RELICENSE/chachoi.md ]; then
    echo "SUCCESS: RELICENSE/chachoi.md file present"
    test_status=0
else
    echo "FAIL: RELICENSE/chachoi.md file missing"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

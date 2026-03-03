#!/bin/bash

cd /app/src

# Environment variables for tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "php/tests"
cp "/tests/php/tests/DescriptorsTest.php" "php/tests/DescriptorsTest.php"

# Run PHPUnit on the specific test file
cd php
vendor/bin/phpunit tests/DescriptorsTest.php
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

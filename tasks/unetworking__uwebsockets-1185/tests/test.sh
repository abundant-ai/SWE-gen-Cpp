#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/Makefile" "tests/Makefile"
cp "/tests/TopicTree.cpp" "tests/TopicTree.cpp"

# Compile and run TopicTree test
cd tests
${CXX:-g++} -std=c++17 -fsanitize=address TopicTree.cpp -o TopicTree
./TopicTree
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/user_counters_test.cc" "test/user_counters_test.cc"

# This task checks if the code compiles with -Werror=old-style-cast
# The buggy code has C-style casts which should fail with this flag
# The fixed code uses static_cast which should compile successfully

echo "Testing compilation with -Werror=old-style-cast..."
rm -rf build
cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_FLAGS="-Werror=old-style-cast" \
    -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
    -DBENCHMARK_ENABLE_TESTING=ON \
    -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
    -DBENCHMARK_ENABLE_WERROR=OFF \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cmake --build build --config Debug --target user_counters_test -j 1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo "SUCCESS: Code compiles with -Werror=old-style-cast"
else
  echo "FAILURE: Code fails to compile with -Werror=old-style-cast (has C-style casts)"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

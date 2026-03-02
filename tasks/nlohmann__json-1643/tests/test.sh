#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-regression.cpp" "test/src/unit-regression.cpp"

# Create a test file that properly triggers the bug by defining type aliases BEFORE including json.hpp
cat > test_regression_1642.cpp << 'EOF'
// Regression test for issue #1642: the 'string' type alias must be defined BEFORE the include
// to trigger the compilation error in the buggy version
// We only define 'string' to avoid triggering other unrelated parts of the codebase
template <typename T> class string {};

#include "single_include/nlohmann/json.hpp"

int main() {
    using nlohmann::json;
    json j1 = "test";
    json j2 = "test2";
    // This comparison will fail to compile in the buggy version due to the type alias collision
    bool result = (j1 < j2);
    return result ? 0 : 1;
}
EOF

# Try to compile the regression test
# This will FAIL in the buggy (BASE) state and SUCCEED in the fixed (HEAD) state
clang++-14 -std=c++17 test_regression_1642.cpp -o test_regression_1642 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

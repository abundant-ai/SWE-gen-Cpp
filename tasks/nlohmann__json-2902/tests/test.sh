#!/bin/bash

cd /app/src

# For this PR, the test is whether the code compiles with -Wuseless-cast enabled
# Create a minimal test program that includes the JSON header
cat > /tmp/test_useless_cast.cpp << 'EOF'
#include <nlohmann/json.hpp>
int main(){return 0;}
EOF

# Try to compile with -Wuseless-cast -Werror
# In BASE state (after bug.patch): code has static_cast<std::size_t>(len) which triggers warnings
# In HEAD state: code uses conditional_static_cast<std::size_t>(len) which avoids warnings
g++ -std=c++17 -Wuseless-cast -Werror -I/app/src/include /tmp/test_useless_cast.cpp -o /tmp/test_useless_cast 2>&1 | tee /tmp/build_output.txt
test_status=${PIPESTATUS[0]}

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

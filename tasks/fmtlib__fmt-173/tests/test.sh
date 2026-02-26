#!/bin/bash

cd /app/src

# Build the library first
cmake --build build --target format 2>&1 | head -20

# Test if named arguments feature is implemented
# The bug is that named arguments (using identifiers instead of indices) are not supported
# The fix implements support for named arguments via fmt::arg()

# Create a test program that uses named arguments
cat > /tmp/test_named_args.cc << 'EOF'
#include "format.h"
#include <iostream>

int main() {
  try {
    // Test basic named argument
    std::string result1 = fmt::format("Hello, {name}!", fmt::arg("name", "World"));
    if (result1 != "Hello, World!") {
      std::cerr << "FAIL: Expected 'Hello, World!' but got '" << result1 << "'" << std::endl;
      return 1;
    }

    // Test multiple named arguments
    std::string result2 = fmt::format("{greet}, {user}!", fmt::arg("greet", "Hi"), fmt::arg("user", "Alice"));
    if (result2 != "Hi, Alice!") {
      std::cerr << "FAIL: Expected 'Hi, Alice!' but got '" << result2 << "'" << std::endl;
      return 1;
    }

    // Test mixing positional and named arguments
    std::string result3 = fmt::format("{0} scored {points}", "Bob", fmt::arg("points", 42));
    if (result3 != "Bob scored 42") {
      std::cerr << "FAIL: Expected 'Bob scored 42' but got '" << result3 << "'" << std::endl;
      return 1;
    }

    std::cout << "SUCCESS: All named argument tests passed!" << std::endl;
    return 0;

  } catch (const std::exception& e) {
    std::cerr << "FAIL: Exception thrown: " << e.what() << std::endl;
    return 1;
  }
}
EOF

# Try to compile and run the test
g++ -std=c++11 -I. -Ibuild -o /tmp/test_named_args /tmp/test_named_args.cc build/libformat.a -lpthread 2>&1
compile_status=$?

if [ $compile_status -ne 0 ]; then
  # Compilation failed - named arguments not implemented (BASE state)
  echo "Named arguments feature not implemented (compilation failed)"
  test_status=1
else
  # Compilation succeeded - try to run the test
  /tmp/test_named_args
  test_status=$?

  if [ $test_status -eq 0 ]; then
    echo "Named arguments feature working correctly (HEAD state)"
  else
    echo "Named arguments feature compiled but tests failed"
  fi
fi

# Write reward
mkdir -p /logs/verifier
if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

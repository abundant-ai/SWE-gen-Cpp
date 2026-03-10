#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/module-test.cc" "test/module-test.cc"

# Build the fmt library first
cd build
cmake --build . --target fmt
lib_build_status=$?

if [ $lib_build_status -ne 0 ]; then
  echo "Failed to build fmt library" >&2
  test_status=1
else
  # Test whether make_args_checked is deprecated or not
  # In FIXED state: FMT_DEPRECATED is present, so using it triggers a warning
  # In BUGGY state: FMT_DEPRECATED is removed, so no warning
  cat > /tmp/test_deprecation.cc << 'EOF'
#include <fmt/format.h>

int main() {
  // Use make_args_checked directly - this should warn in fixed state
  auto args = fmt::make_args_checked<int>("{}", 42);
  return 0;
}
EOF

  cd /app/src
  # Compile with warnings as errors for deprecation
  g++ -std=c++20 -Werror=deprecated-declarations -I/app/src/include -L/app/src/build \
      /tmp/test_deprecation.cc -lfmt -o /tmp/test_runner 2>&1
  compile_status=$?

  if [ $compile_status -eq 0 ]; then
    # Compilation succeeded without deprecation warning - this is BUGGY state
    # (make_args_checked is NOT deprecated)
    LD_LIBRARY_PATH=/app/src/build /tmp/test_runner
    run_status=$?
    # In buggy state, we expect success (no deprecation), so test fails (reward=0)
    test_status=1
  else
    # Compilation failed due to deprecation warning - this is FIXED state
    # (make_args_checked IS deprecated, which is correct)
    echo "Deprecation warning detected (correct - fixed state)" >&2
    # In fixed state, we expect deprecation warning, so test passes (reward=1)
    test_status=0
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

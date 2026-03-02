#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/fuzzing"
cp "/tests/fuzzing/README.md" "test/fuzzing/README.md"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

test_status=0

# Verify that the source code has been fixed to use FMT_FUZZ instead of FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION
echo "Verifying source code uses FMT_FUZZ macro..."

# Check format.h
if ! grep -q "#ifdef FMT_FUZZ" include/fmt/format.h; then
    echo "FAIL: include/fmt/format.h does not use FMT_FUZZ macro"
    test_status=1
fi

# Check format-inl.h
if [ $test_status -eq 0 ]; then
    if ! grep -q "#ifdef FMT_FUZZ" include/fmt/format-inl.h; then
        echo "FAIL: include/fmt/format-inl.h does not use FMT_FUZZ macro"
        test_status=1
    fi
fi

# Check format.cc
if [ $test_status -eq 0 ]; then
    if ! grep -q "#ifdef FMT_FUZZ" src/format.cc; then
        echo "FAIL: src/format.cc does not use FMT_FUZZ macro"
        test_status=1
    fi
fi

# Check CMakeLists.txt for the FMT_FUZZ definition
if [ $test_status -eq 0 ]; then
    if ! grep -q "target_compile_definitions(fmt PUBLIC FMT_FUZZ)" CMakeLists.txt; then
        echo "FAIL: CMakeLists.txt does not define FMT_FUZZ"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
    echo "PASS: All source files correctly use FMT_FUZZ macro"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

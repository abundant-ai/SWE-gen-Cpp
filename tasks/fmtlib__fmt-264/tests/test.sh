#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"

# Clean build directory to avoid CMake cache issues
rm -rf build

# Reconfigure with the updated test files
# This PR is about CMake package configuration, so we need to test that
# the exported targets and config files are generated correctly
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_STANDARD=14 \
    -DCMAKE_INSTALL_PREFIX=/tmp/fmt-install \
    -DFMT_TEST=ON \
    -DFMT_INSTALL=ON 2>&1

cmake_status=$?

if [ $cmake_status -ne 0 ]; then
  test_status=1
else
  # Test that the CMake package config files are generated during configuration
  # The fix should create cppformatConfig.cmake and cppformatConfigVersion.cmake
  # These are generated during the cmake configuration step, not during build
  if [ -f "build/cppformatConfig.cmake" ] && [ -f "build/cppformatConfigVersion.cmake" ]; then
    # Also verify the targets export file is generated
    if [ -f "build/cppformatTargets.cmake" ]; then
      test_status=0
    else
      echo "ERROR: cppformatTargets.cmake not found"
      ls -la build/*.cmake 2>&1 || true
      test_status=1
    fi
  else
    echo "ERROR: CMake config files not found - fix not applied correctly"
    echo "Expected: build/cppformatConfig.cmake and build/cppformatConfigVersion.cmake"
    ls -la build/*.cmake 2>&1 || true
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

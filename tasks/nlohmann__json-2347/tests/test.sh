#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/cmake_add_subdirectory/project"
cp "/tests/cmake_add_subdirectory/project/CMakeLists.txt" "test/cmake_add_subdirectory/project/CMakeLists.txt"
cp "/tests/cmake_add_subdirectory/project/main.cpp" "test/cmake_add_subdirectory/project/main.cpp"

# Reconfigure and run cmake_add_subdirectory tests
cd build
cmake -S .. -B . -G Ninja -DJSON_BuildTests=ON -DCMAKE_CXX_STANDARD=17 -DJSON_CI=ON
ctest -R cmake_add_subdirectory --output-on-failure
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

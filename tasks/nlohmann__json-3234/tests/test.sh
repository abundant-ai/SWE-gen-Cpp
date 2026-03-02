#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/cuda_example"
cp "/tests/cuda_example/json_cuda.cu" "test/cuda_example/json_cuda.cu"

# Configure CMake for the CUDA test
# Using g++-10 as host compiler for compatibility with CUDA 11.5
cmake -S test/cuda_example -B build_cuda_example \
    -DCMAKE_CUDA_COMPILER=/usr/local/cuda-11.5/bin/nvcc \
    -DCMAKE_CUDA_HOST_COMPILER=g++-10

# Build the CUDA test - this is the actual test (compilation must succeed with fix, fail with bug)
cmake --build build_cuda_example
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

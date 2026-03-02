#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-bson.cpp" "test/src/unit-bson.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-cbor.cpp" "test/src/unit-cbor.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-comparison.cpp" "test/src/unit-comparison.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-constructor1.cpp" "test/src/unit-constructor1.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-constructor2.cpp" "test/src/unit-constructor2.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-convenience.cpp" "test/src/unit-convenience.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-element_access1.cpp" "test/src/unit-element_access1.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-inspection.cpp" "test/src/unit-inspection.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-modifiers.cpp" "test/src/unit-modifiers.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-msgpack.cpp" "test/src/unit-msgpack.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-pointer_access.cpp" "test/src/unit-pointer_access.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-serialization.cpp" "test/src/unit-serialization.cpp"

# Reconfigure CMake to pick up the updated test files
cd build
cmake -S .. -B . -G Ninja -DJSON_BuildTests=ON -DCMAKE_CXX_STANDARD=17 -DJSON_CI=ON

# Build the specific tests for this PR (one at a time to avoid OOM)
cmake --build . --target test-bson --parallel 1
cmake --build . --target test-cbor --parallel 1
cmake --build . --target test-comparison --parallel 1
cmake --build . --target test-constructor1 --parallel 1
cmake --build . --target test-constructor2 --parallel 1
cmake --build . --target test-convenience --parallel 1
cmake --build . --target test-element_access1 --parallel 1
cmake --build . --target test-inspection --parallel 1
cmake --build . --target test-modifiers --parallel 1
cmake --build . --target test-msgpack --parallel 1
cmake --build . --target test-pointer_access --parallel 1
cmake --build . --target test-serialization --parallel 1

# Run the specific unit tests
ctest -R "test-(bson|cbor|comparison|constructor1|constructor2|convenience|element_access1|inspection|modifiers|msgpack|pointer_access|serialization)" --output-on-failure
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

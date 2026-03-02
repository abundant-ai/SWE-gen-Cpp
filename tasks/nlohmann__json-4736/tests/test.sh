#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-deserialization.cpp" "tests/src/unit-deserialization.cpp"

# Check fix 1: In from_json.hpp, should use __cpp_lib_char8_t, not JSON_HAS_CPP_20
# In BASE state (bug), it uses: #ifdef JSON_HAS_CPP_20
# In HEAD state (fixed), it uses: #if defined(__cpp_lib_char8_t) && (__cpp_lib_char8_t >= 201907L)
if grep -A5 "const auto& s = \*j.template get_ptr" include/nlohmann/detail/conversions/from_json.hpp | grep -q "JSON_HAS_CPP_20"; then
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi

if ! grep -A5 "const auto& s = \*j.template get_ptr" include/nlohmann/detail/conversions/from_json.hpp | grep -q "__cpp_lib_char8_t"; then
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi

# Check fix 2: In to_json.hpp, should have #include <memory>
# In BASE state (bug), it doesn't have this include
# In HEAD state (fixed), it has: #include <memory>
if ! grep -q "#include <memory>" include/nlohmann/detail/conversions/to_json.hpp; then
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi

# Check fix 3: In to_json.hpp, the char8_t overload should exist
# In BASE state (bug), this function doesn't exist
# In HEAD state (fixed), there's a to_json function for std::basic_string<char8_t>
if ! grep -q "std::basic_string<char8_t" include/nlohmann/detail/conversions/to_json.hpp; then
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi

# Check fix 4: The path to_json should just use p.u8string() directly
# In BASE state (bug), it has #ifdef JSON_HAS_CPP_20 with manual conversion
# In HEAD state (fixed), it just does: j = p.u8string();
if grep -A10 "inline void to_json.*const std_fs::path& p" include/nlohmann/detail/conversions/to_json.hpp | grep -q "JSON_HAS_CPP_20"; then
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi

# All source code fixes are present - now verify the code compiles and tests pass
cmake -S . -B build_verify -DJSON_BuildTests=ON > /dev/null 2>&1 || { echo 0 > /logs/verifier/reward.txt; exit 1; }
cmake --build build_verify --target download_test_data > /dev/null 2>&1 || true
cmake --build build_verify --target test-deserialization_cpp11 > /dev/null 2>&1 || { echo 0 > /logs/verifier/reward.txt; exit 1; }

# Run the test
./build_verify/tests/test-deserialization_cpp11 > /dev/null 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

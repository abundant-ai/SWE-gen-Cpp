#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-regression2.cpp" "tests/src/unit-regression2.cpp"

# Check fix 1: In from_json.hpp, the #include <optional> should be AFTER "include after macro_scope.hpp" comment
# In BASE state (bug), the #include <optional> is moved to be right after #include <map> (too early)
# In HEAD state (fixed), it's after the "include after macro_scope.hpp" comment
if grep -A3 '#include <map>' include/nlohmann/detail/conversions/from_json.hpp | grep -q '#include <optional>'; then
    # If optional is right after map, that's the BASE (buggy) state
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi

# Verify the optional include is in the correct location (after macro_scope comment)
if ! grep -A3 '// include after macro_scope.hpp' include/nlohmann/detail/conversions/from_json.hpp | grep -q '#include <optional>'; then
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi

# Check fix 2: The from_json function for std::optional should NOT be inside #ifndef JSON_USE_IMPLICIT_CONVERSIONS
# In BASE state (bug), the function IS inside #ifndef JSON_USE_IMPLICIT_CONVERSIONS
# In HEAD state (fixed), there should be NO #ifndef JSON_USE_IMPLICIT_CONVERSIONS guard
# We check the area around the from_json<std::optional> function
if grep -B2 -A15 "void from_json.*optional" include/nlohmann/detail/conversions/from_json.hpp | grep -q "#ifndef JSON_USE_IMPLICIT_CONVERSIONS"; then
    # If we find the guard, that's the BASE (buggy) state
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi

# Check fix 3: In to_json.hpp, the to_json function for std::optional should have noexcept
# In BASE state (bug), it doesn't have noexcept
# In HEAD state (fixed), it has noexcept
if ! grep "void to_json.*optional.*noexcept" include/nlohmann/detail/conversions/to_json.hpp > /dev/null; then
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi

# All source code fixes are present - now verify the code compiles and tests pass
cmake -S . -B build_verify -DJSON_BuildTests=ON > /dev/null 2>&1 || { echo 0 > /logs/verifier/reward.txt; exit 1; }
cmake --build build_verify --target download_test_data > /dev/null 2>&1 || true
cmake --build build_verify --target test-regression2_cpp11 > /dev/null 2>&1 || { echo 0 > /logs/verifier/reward.txt; exit 1; }

# Run the test
./build_verify/tests/test-regression2_cpp11 > /dev/null 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

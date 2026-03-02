#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-class_parser.cpp" "tests/src/unit-class_parser.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-deserialization.cpp" "tests/src/unit-deserialization.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-element_access2.cpp" "tests/src/unit-element_access2.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-json_patch.cpp" "tests/src/unit-json_patch.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-json_pointer.cpp" "tests/src/unit-json_pointer.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-merge_patch.cpp" "tests/src/unit-merge_patch.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-msgpack.cpp" "tests/src/unit-msgpack.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-readme.cpp" "tests/src/unit-readme.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-regression1.cpp" "tests/src/unit-regression1.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-regression2.cpp" "tests/src/unit-regression2.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-udl.cpp" "tests/src/unit-udl.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-udt.cpp" "tests/src/unit-udt.cpp"

# Re-configure and build with the updated test files
cmake -S . -B build_test -DJSON_BuildTests=ON > /tmp/cmake_output.txt 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    cat /tmp/cmake_output.txt
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Download test data for the new build directory
cmake --build build_test --target download_test_data > /tmp/download_test_data.txt 2>&1

# Build and run the test executables that correspond to the modified test files
test_status=0

# Build and run test-class_parser_cpp11
target="test-class_parser_cpp11"
echo "Building and running ${target}..."
cmake --build build_test --target ${target} 2>&1 | tee /tmp/build_${target}.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/${target} 2>&1 | tee /tmp/test_${target}.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

# Build and run test-deserialization_cpp11
target="test-deserialization_cpp11"
echo "Building and running ${target}..."
cmake --build build_test --target ${target} 2>&1 | tee /tmp/build_${target}.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/${target} 2>&1 | tee /tmp/test_${target}.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

# Build and run test-element_access2_cpp11
target="test-element_access2_cpp11"
echo "Building and running ${target}..."
cmake --build build_test --target ${target} 2>&1 | tee /tmp/build_${target}.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/${target} 2>&1 | tee /tmp/test_${target}.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

# Build and run test-json_patch_cpp11
target="test-json_patch_cpp11"
echo "Building and running ${target}..."
cmake --build build_test --target ${target} 2>&1 | tee /tmp/build_${target}.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/${target} 2>&1 | tee /tmp/test_${target}.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

# Build and run test-json_pointer_cpp11
target="test-json_pointer_cpp11"
echo "Building and running ${target}..."
cmake --build build_test --target ${target} 2>&1 | tee /tmp/build_${target}.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/${target} 2>&1 | tee /tmp/test_${target}.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

# Build and run test-merge_patch_cpp11
target="test-merge_patch_cpp11"
echo "Building and running ${target}..."
cmake --build build_test --target ${target} 2>&1 | tee /tmp/build_${target}.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/${target} 2>&1 | tee /tmp/test_${target}.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

# Build and run test-msgpack_cpp11
target="test-msgpack_cpp11"
echo "Building and running ${target}..."
cmake --build build_test --target ${target} 2>&1 | tee /tmp/build_${target}.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/${target} 2>&1 | tee /tmp/test_${target}.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

# Build and run test-readme_cpp11
target="test-readme_cpp11"
echo "Building and running ${target}..."
cmake --build build_test --target ${target} 2>&1 | tee /tmp/build_${target}.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/${target} 2>&1 | tee /tmp/test_${target}.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

# Build and run test-regression1_cpp11
target="test-regression1_cpp11"
echo "Building and running ${target}..."
cmake --build build_test --target ${target} 2>&1 | tee /tmp/build_${target}.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/${target} 2>&1 | tee /tmp/test_${target}.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

# Build and run test-regression2_cpp11
target="test-regression2_cpp11"
echo "Building and running ${target}..."
cmake --build build_test --target ${target} 2>&1 | tee /tmp/build_${target}.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/${target} 2>&1 | tee /tmp/test_${target}.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

# Build and run test-udl_cpp11
target="test-udl_cpp11"
echo "Building and running ${target}..."
cmake --build build_test --target ${target} 2>&1 | tee /tmp/build_${target}.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/${target} 2>&1 | tee /tmp/test_${target}.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

# Build and run test-udt_cpp11
target="test-udt_cpp11"
echo "Building and running ${target}..."
cmake --build build_test --target ${target} 2>&1 | tee /tmp/build_${target}.txt
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    build_test/tests/${target} 2>&1 | tee /tmp/test_${target}.txt
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        test_status=1
    fi
else
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

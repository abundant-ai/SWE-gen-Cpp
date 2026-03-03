#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "unittests/modules"
cp "/tests/unittests/modules/test_cxx_modules.cpp" "unittests/modules/test_cxx_modules.cpp"

# Check if modules subdirectory is in CMakeLists.txt (fix.patch adds it, bug.patch removes it)
if ! grep -q "add_subdirectory(\${TF_UTEST_DIR}/modules)" unittests/CMakeLists.txt; then
  # Re-add modules subdirectory to CMakeLists.txt (needed for NOP path)
  sed -i '/doctest_discover_tests(${unittest})/a\\n# include C++ module tests\nif(TF_BUILD_MODULES)\n  add_subdirectory(${TF_UTEST_DIR}/modules)\nendif()' unittests/CMakeLists.txt
fi

# Create modules/CMakeLists.txt if it doesn't exist (needed for NOP path)
if [ ! -f "unittests/modules/CMakeLists.txt" ]; then
  cat > unittests/modules/CMakeLists.txt << 'EOF'
include(${TF_3RD_PARTY_DIR}/doctest/doctest.cmake)

add_executable(test_cxx_modules test_cxx_modules.cpp)

set_target_properties(test_cxx_modules PROPERTIES CXX_SCAN_FOR_MODULES ON)

target_link_libraries(test_cxx_modules
  tf_module
  ${ATOMIC_LIBRARY}
  tf::default_settings
)

target_include_directories(test_cxx_modules PRIVATE ${TF_3RD_PARTY_DIR}/doctest)

doctest_discover_tests(test_cxx_modules)
EOF
fi

# Reconfigure CMake now that the test file and CMakeLists exist (use Ninja and libc++ for C++20 modules)
cmake -S . -B build -GNinja -DCMAKE_BUILD_TYPE=Release -DTF_BUILD_MODULES=ON \
  -DCMAKE_CXX_FLAGS="-stdlib=libc++" -DCMAKE_EXE_LINKER_FLAGS="-lc++abi"

# Remove old build artifacts for test_cxx_modules to force rebuild
rm -f build/unittests/modules/test_cxx_modules build/unittests/modules/CMakeFiles/test_cxx_modules.dir/test_cxx_modules.cpp.o

# Rebuild the test binary (this will fail on buggy code)
cmake --build build --target test_cxx_modules --parallel $(nproc)
build_status=$?

# If build failed, that means tests fail (reward=0)
if [ $build_status -ne 0 ]; then
  echo "Build failed - test cannot run (expected on buggy code)" >&2
  test_status=1
else
  # Run the specific test binary
  ./build/unittests/modules/test_cxx_modules
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

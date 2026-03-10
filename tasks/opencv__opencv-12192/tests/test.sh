#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgcodecs/test"
cp "/tests/modules/imgcodecs/test/test_grfmt.cpp" "modules/imgcodecs/test/test_grfmt.cpp"

checks_passed=0
checks_failed=0

# PR #12192: Add PFM (Portable Float Map) image format support
# The fix adds PFM format reading/writing capabilities to OpenCV's imgcodecs module

# Check 1: CMake should have WITH_IMGCODEC_PFM option
if grep -q 'OCV_OPTION(WITH_IMGCODEC_PFM' CMakeLists.txt; then
    echo "PASS: CMakeLists.txt has WITH_IMGCODEC_PFM option"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt should have WITH_IMGCODEC_PFM option" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: CMake should have PFM status output
if grep -q 'status("    PFM:"' CMakeLists.txt; then
    echo "PASS: CMakeLists.txt has PFM status output"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: CMakeLists.txt should have PFM status output" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: OpenCVFindLibsGrfmt.cmake should handle HAVE_IMGCODEC_PFM
if grep -q 'if(WITH_IMGCODEC_PFM)' cmake/OpenCVFindLibsGrfmt.cmake; then
    echo "PASS: OpenCVFindLibsGrfmt.cmake handles WITH_IMGCODEC_PFM"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: OpenCVFindLibsGrfmt.cmake should handle WITH_IMGCODEC_PFM" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: modules/imgcodecs/CMakeLists.txt should add HAVE_IMGCODEC_PFM definition
if grep -q 'if (HAVE_IMGCODEC_PFM)' modules/imgcodecs/CMakeLists.txt; then
    echo "PASS: modules/imgcodecs/CMakeLists.txt checks HAVE_IMGCODEC_PFM"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: modules/imgcodecs/CMakeLists.txt should check HAVE_IMGCODEC_PFM" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: grfmt_pfm.cpp should exist
if [ -f modules/imgcodecs/src/grfmt_pfm.cpp ]; then
    echo "PASS: grfmt_pfm.cpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_pfm.cpp should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: grfmt_pfm.hpp should exist
if [ -f modules/imgcodecs/src/grfmt_pfm.hpp ]; then
    echo "PASS: grfmt_pfm.hpp exists"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_pfm.hpp should exist" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: grfmt_pfm.hpp should have PFMDecoder class
if [ -f modules/imgcodecs/src/grfmt_pfm.hpp ] && grep -q 'class PFMDecoder' modules/imgcodecs/src/grfmt_pfm.hpp; then
    echo "PASS: grfmt_pfm.hpp has PFMDecoder class"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_pfm.hpp should have PFMDecoder class" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: grfmt_pfm.hpp should have PFMEncoder class
if [ -f modules/imgcodecs/src/grfmt_pfm.hpp ] && grep -q 'class PFMEncoder' modules/imgcodecs/src/grfmt_pfm.hpp; then
    echo "PASS: grfmt_pfm.hpp has PFMEncoder class"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_pfm.hpp should have PFMEncoder class" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: grfmts.hpp should include grfmt_pfm.hpp
if grep -q '#include "grfmt_pfm.hpp"' modules/imgcodecs/src/grfmts.hpp; then
    echo "PASS: grfmts.hpp includes grfmt_pfm.hpp"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmts.hpp should include grfmt_pfm.hpp" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: loadsave.cpp should register PFMDecoder
if grep -q 'makePtr<PFMDecoder>' modules/imgcodecs/src/loadsave.cpp; then
    echo "PASS: loadsave.cpp registers PFMDecoder"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: loadsave.cpp should register PFMDecoder" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 11: loadsave.cpp should register PFMEncoder
if grep -q 'makePtr<PFMEncoder>' modules/imgcodecs/src/loadsave.cpp; then
    echo "PASS: loadsave.cpp registers PFMEncoder"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: loadsave.cpp should register PFMEncoder" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 12: PFMDecoder should handle both 'f' and 'F' magic bytes (for Pf and PF)
if [ -f modules/imgcodecs/src/grfmt_pfm.cpp ] && grep -q "'f'" modules/imgcodecs/src/grfmt_pfm.cpp && grep -q "'F'" modules/imgcodecs/src/grfmt_pfm.cpp; then
    echo "PASS: grfmt_pfm.cpp handles both f and F magic bytes"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_pfm.cpp should handle both f and F magic bytes" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 13: grfmt_pfm.cpp should have is_byte_order_swapped function
if [ -f modules/imgcodecs/src/grfmt_pfm.cpp ] && grep -q 'is_byte_order_swapped' modules/imgcodecs/src/grfmt_pfm.cpp; then
    echo "PASS: grfmt_pfm.cpp has is_byte_order_swapped function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_pfm.cpp should have is_byte_order_swapped function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 14: grfmt_pfm.cpp should have swap_endianess function
if [ -f modules/imgcodecs/src/grfmt_pfm.cpp ] && grep -q 'swap_endianess' modules/imgcodecs/src/grfmt_pfm.cpp; then
    echo "PASS: grfmt_pfm.cpp has swap_endianess function"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_pfm.cpp should have swap_endianess function" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 15: PFMEncoder should handle 1 and 3 channel images
if [ -f modules/imgcodecs/src/grfmt_pfm.cpp ] && grep -q 'case 1:' modules/imgcodecs/src/grfmt_pfm.cpp && grep -q 'case 3:' modules/imgcodecs/src/grfmt_pfm.cpp; then
    echo "PASS: grfmt_pfm.cpp handles 1 and 3 channel images"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: grfmt_pfm.cpp should handle 1 and 3 channel images" >&2
    checks_failed=$((checks_failed + 1))
fi

echo "Checks passed: $checks_passed, Checks failed: $checks_failed"

if [ $checks_failed -eq 0 ]; then
    test_status=0
else
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

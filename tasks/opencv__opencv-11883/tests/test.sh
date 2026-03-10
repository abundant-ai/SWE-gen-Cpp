#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/python/test"
cp "/tests/modules/python/test/test_persistence.py" "modules/python/test/test_persistence.py"

checks_passed=0
checks_failed=0

# PR #11883: Add support for writing Python sequences of strings to FileStorage

# Check 1: persistence.hpp should have separate overloads for Mat and vector<String>
if grep -q 'CV_WRAP void write(const String& name, const Mat& val);' modules/core/include/opencv2/core/persistence.hpp 2>/dev/null && \
   grep -q 'CV_WRAP void write(const String& name, const std::vector<String>& val);' modules/core/include/opencv2/core/persistence.hpp 2>/dev/null; then
    echo "PASS: FileStorage has separate write() overloads for Mat and vector<String>"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: FileStorage should have separate write() overloads for Mat and vector<String>, not just InputArray" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: persistence_cpp.cpp should have implementation for Mat overload
if grep -q 'void FileStorage::write( const String& name, const Mat& val )' modules/core/src/persistence_cpp.cpp 2>/dev/null && \
   grep -q '\*this << name << val;' modules/core/src/persistence_cpp.cpp 2>/dev/null; then
    echo "PASS: FileStorage::write() has Mat overload implementation"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: FileStorage::write() should have Mat overload with direct write implementation" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: persistence_cpp.cpp should have implementation for vector<String> overload
if grep -q 'void FileStorage::write( const String& name, const std::vector<String>& val )' modules/core/src/persistence_cpp.cpp 2>/dev/null; then
    echo "PASS: FileStorage::write() has vector<String> overload implementation"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: FileStorage::write() should have vector<String> overload implementation" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: Test file should include test for writing string sequences
if grep -q 'expected_str = ("Hello", "World", "!")' modules/python/test/test_persistence.py 2>/dev/null && \
   grep -q 'fs.write("strings", expected_str)' modules/python/test/test_persistence.py 2>/dev/null; then
    echo "PASS: Python test includes string sequence write test"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Python test should include test for writing string sequences" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: Test file should validate reading string sequences back
if grep -q 'strings = fs.getNode("strings")' modules/python/test/test_persistence.py 2>/dev/null && \
   grep -q 'self.assertEqual(strings.isSeq(), True)' modules/python/test/test_persistence.py 2>/dev/null && \
   grep -q 'self.assertEqual(strings.size(), len(expected_str))' modules/python/test/test_persistence.py 2>/dev/null; then
    echo "PASS: Python test validates reading string sequences"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: Python test should validate reading string sequences with isSeq(), size(), etc." >&2
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

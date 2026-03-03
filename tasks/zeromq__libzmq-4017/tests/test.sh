#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_bind_ws_fuzzer.cpp" "tests/test_bind_ws_fuzzer.cpp"

# Add test to CMakeLists.txt so it gets built
cd tests
# Find the line with ZMQ_HAVE_WS and add our test there
sed -i '/if(ZMQ_HAVE_WS)/a\  list(APPEND tests test_bind_ws_fuzzer)' CMakeLists.txt
cd ..

# Rebuild from scratch
# The fix allows the test to work WITHOUT drafts, so don't enable them
rm -rf build
mkdir -p build && cd build
cmake .. -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON
make -j$(nproc) test_bind_ws_fuzzer

# Create minimal corpus directory AFTER build so it's available for test
cd /app/src
mkdir -p "tests/libzmq-fuzz-corpora/test_bind_ws_fuzzer_seed_corpus"
# Create corpus files with minimal WebSocket handshake data
# File 1: Just a simple byte pattern
echo -n -e "\x00\x01\x02\x03" > "tests/libzmq-fuzz-corpora/test_bind_ws_fuzzer_seed_corpus/001"
# File 2: HTTP-like header
echo -n "GET / HTTP/1.1" > "tests/libzmq-fuzz-corpora/test_bind_ws_fuzzer_seed_corpus/002"
# File 3: Empty-ish
echo -n "X" > "tests/libzmq-fuzz-corpora/test_bind_ws_fuzzer_seed_corpus/003"
cd build

# Run the specific test
echo "Running test_bind_ws_fuzzer..."
echo "Current directory: $(pwd)"
echo "Checking for corpus:"
ls -la ../tests/libzmq-fuzz-corpora/test_bind_ws_fuzzer_seed_corpus/ || echo "Corpus directory not found"
./bin/test_bind_ws_fuzzer 2>&1
test_status=$?
echo "Test exited with status: $test_status"

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

#!/bin/bash

cd /app/src

# For this task, we test with batch_size=0 to trigger the bug.
# With the fix (MINIMAL_BATCH_SIZE check), batch_size=0 gets bumped to 32 and works safely.
# Without the fix, batch_size=0 causes undefined behavior.

cat > /app/src/tests/batch_size_test.cpp << 'EOF'
#include <iostream>
#include "simdjson.h"

int main() {
    // Test with batch_size = 0
    // With the fix, this gets bumped to 32 and works
    // Without the fix, this fails

    auto json = R"(1 2 3)"_padded;
    simdjson::dom::parser parser;
    simdjson::dom::document_stream stream;

    auto error = parser.parse_many(json, 0).get(stream);
    if (error) {
        std::cerr << "parse_many failed: " << error << std::endl;
        return 1;
    }

    int count = 0;
    for (auto doc : stream) {
        if (!doc.error()) {
            count++;
        }
    }

    if (count != 3) {
        std::cerr << "Expected 3 documents, got " << count << std::endl;
        return 1;
    }

    std::cout << "Successfully parsed " << count << " documents with batch_size=0" << std::endl;
    return 0;
}
EOF

# Configure CMake
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_ONDEMAND_SAFETY_RAILS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build

# Build the simdjson library
cmake --build build --target simdjson -j=2

# Build the custom test
mkdir -p build/tests
g++ -std=c++20 \
    -I/app/src/include -I/app/src/build \
    -Wno-ambiguous-reversed-operator \
    /app/src/tests/batch_size_test.cpp \
    -o build/tests/batch_size_test \
    -L/app/src/build -lsimdjson -Wl,-rpath,/app/src/build

if [ ! -f build/tests/batch_size_test ]; then
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the test
./build/tests/batch_size_test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

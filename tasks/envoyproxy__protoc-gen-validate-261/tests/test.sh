#!/bin/bash

cd /go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/kitchen_sink.proto" "tests/harness/cases/kitchen_sink.proto"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/repeated.proto" "tests/harness/cases/repeated.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"
mkdir -p "tests/harness/python"
cp "/tests/harness/python/harness.py" "tests/harness/python/harness.py"

# Rebuild the protoc-gen-validate plugin and regenerate test cases after copying the fixed files
make build && make testcases

# Generate harness.pb.go (required by test executor)
cd tests/harness && protoc -I . \
    --go_out="Mvalidate/validate.proto=github.com/envoyproxy/protoc-gen-validate/validate,Mgoogle/protobuf/any.proto=github.com/golang/protobuf/ptypes/any,Mgoogle/protobuf/duration.proto=github.com/golang/protobuf/ptypes/duration,Mgoogle/protobuf/struct.proto=github.com/golang/protobuf/ptypes/struct,Mgoogle/protobuf/timestamp.proto=github.com/golang/protobuf/ptypes/timestamp,Mgoogle/protobuf/wrappers.proto=github.com/golang/protobuf/ptypes/wrappers,Mgoogle/protobuf/descriptor.proto=github.com/golang/protobuf/protoc-gen-go/descriptor,Mgogoproto/gogo.proto=github.com/envoyproxy/protoc-gen-validate/gogoproto:./go" \
    harness.proto
cd /go/src/github.com/envoyproxy/protoc-gen-validate

# Generate Python protobuf files (required for Python harness)
# First generate validate_pb2.py
protoc -I . --python_out=. validate/validate.proto

# Generate harness_pb2.py
cd tests/harness && protoc -I . -I ../.. --python_out=. harness.proto

# Generate test case protobuf files
cd /go/src/github.com/envoyproxy/protoc-gen-validate/tests/harness/cases/other_package
protoc -I . -I ../../../.. --python_out=. ./*.proto

cd /go/src/github.com/envoyproxy/protoc-gen-validate/tests/harness/cases
protoc -I . -I ../../.. --python_out=. ./*.proto

cd /go/src/github.com/envoyproxy/protoc-gen-validate

# Create __init__.py files to make tests a proper Python package
touch validate/__init__.py
touch tests/__init__.py
touch tests/harness/__init__.py
touch tests/harness/cases/__init__.py
touch tests/harness/cases/other_package/__init__.py

# Create python-harness wrapper script (executor expects this executable)
cat > tests/harness/python/python-harness << 'EOF'
#!/bin/bash
cd /go/src/github.com/envoyproxy/protoc-gen-validate
export PYTHONPATH=/go/src/github.com/envoyproxy/protoc-gen-validate:$PYTHONPATH
python3 tests/harness/python/harness.py
EOF
chmod +x tests/harness/python/python-harness

# Run the Python test harness
# This tests Python validation for all test cases including the ones modified in this PR
# The test harness (executor) will run Python validation on all test cases defined in cases.go
go run ./tests/harness/executor/*.go -python
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

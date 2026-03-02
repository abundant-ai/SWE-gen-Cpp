#!/bin/bash

cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true
test_status=1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/repeated.proto" "tests/harness/cases/repeated.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# Rebuild to regenerate validation code from updated proto files
echo "Rebuilding to regenerate validation code..."
if ! GO111MODULE=off make build 2>&1; then
    echo "✗ Build failed - code generation likely failed due to missing lookup tables"
else
    echo "✓ Build succeeded"

    # Generate test harness Go files from proto files
    echo "Generating test harness..."
    if ! GO111MODULE=off make testcases 2>&1; then
        echo "✗ Test case generation failed"
    else
        echo "✓ Test cases generated"

        # Generate harness.pb.go
        echo "Generating harness proto..."
        if ! GO111MODULE=off make tests/harness/go/harness.pb.go 2>&1; then
            echo "✗ Harness proto generation failed"
        else
            echo "✓ Harness proto generated"

            # Build the Go harness binary
            echo "Building Go harness binary..."
            if ! GO111MODULE=off make tests/harness/go/main/go-harness 2>&1; then
                echo "✗ Harness binary build failed"
            else
                echo "✓ Harness binary built"

                # Run the harness to validate repeated enum test cases
                echo "Running harness validation for Go..."
                if GO111MODULE=off go run ./tests/harness/executor/*.go -go 2>&1 | tee /tmp/test_output.log; then
                    # Check if all tests passed (Failures: 0 means success)
                    if grep -q "Failures: 0" /tmp/test_output.log; then
                        echo "✓ Repeated enum validation tests passed"
                        test_status=0
                    else
                        echo "✗ Some tests failed"
                        echo "Summary:"
                        grep "Successes.*Failures" /tmp/test_output.log
                    fi
                else
                    echo "✗ Harness execution failed"
                    tail -20 /tmp/test_output.log
                fi
            fi
        fi
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

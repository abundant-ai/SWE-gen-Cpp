#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "java/pgv-java-grpc/src/test/java/com/lyft/pgv/grpc"
cp "/tests/java/pgv-java-grpc/src/test/java/com/lyft/pgv/grpc/ValidatingClientInterceptorTest.java" "java/pgv-java-grpc/src/test/java/com/lyft/pgv/grpc/ValidatingClientInterceptorTest.java"
mkdir -p "java/pgv-java-grpc/src/test/java/com/lyft/pgv/grpc"
cp "/tests/java/pgv-java-grpc/src/test/java/com/lyft/pgv/grpc/ValidatingServerInterceptorTest.java" "java/pgv-java-grpc/src/test/java/com/lyft/pgv/grpc/ValidatingServerInterceptorTest.java"

# Clean cached compiled classes to ensure fresh compilation with current source state
cd java/pgv-java-grpc && mvn clean

# Run the specific Java test files for this PR (in the pgv-java-grpc module)
mvn test -Dtest=ValidatingClientInterceptorTest,ValidatingServerInterceptorTest
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

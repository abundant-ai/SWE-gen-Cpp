#!/bin/bash

cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc"
cp "/tests/java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc/ValidatingClientInterceptorTest.java" "java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc/ValidatingClientInterceptorTest.java"
mkdir -p "java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc"
cp "/tests/java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc/ValidatingServerInterceptorTest.java" "java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc/ValidatingServerInterceptorTest.java"

# Compile the pgv-java-grpc module (including proto files and test code)
cd java
mvn test-compile -pl pgv-java-grpc -am

# Run the specific test classes for this PR
cd pgv-java-grpc
mvn surefire:test -Dtest=ValidatingClientInterceptorTest,ValidatingServerInterceptorTest
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

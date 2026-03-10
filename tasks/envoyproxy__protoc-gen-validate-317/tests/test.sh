#!/bin/bash

cd /go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc"
cp "/tests/java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc/ValidatingClientInterceptorTest.java" "java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc/ValidatingClientInterceptorTest.java"
mkdir -p "java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc"
cp "/tests/java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc/ValidatingServerInterceptorTest.java" "java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc/ValidatingServerInterceptorTest.java"

# Recompile Java modules after changes (the agent may have applied a fix)
cd java && mvn clean install -DskipTests

# Run specific test classes with Maven
mvn test -Dtest=ValidatingClientInterceptorTest,ValidatingServerInterceptorTest -pl pgv-java-grpc
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

#!/bin/bash

cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc"
cp "/tests/java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc/ValidatingClientInterceptorTest.java" "java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc/ValidatingClientInterceptorTest.java"
mkdir -p "java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc"
cp "/tests/java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc/ValidatingServerInterceptorTest.java" "java/pgv-java-grpc/src/test/java/io/envoyproxy/pgv/grpc/ValidatingServerInterceptorTest.java"
mkdir -p "java/pgv-java-grpc/src/test/proto"
cp "/tests/java/pgv-java-grpc/src/test/proto/hello.proto" "java/pgv-java-grpc/src/test/proto/hello.proto"

# Apply the fix patch to enable java_multiple_files support
patch -p1 < /solution/fix.patch

# Rebuild the Go plugin with the fix
GO111MODULE=off make build

# Rebuild Java project with the fix to regenerate validators for java_multiple_files
cd java && mvn clean install -DskipTests

# Run the specific test files for this PR (only in pgv-java-grpc module)
cd /root/go/src/github.com/envoyproxy/protoc-gen-validate/java/pgv-java-grpc
mvn test -Dtest=ValidatingClientInterceptorTest,ValidatingServerInterceptorTest
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

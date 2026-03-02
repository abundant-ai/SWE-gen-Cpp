#!/bin/bash

cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "java/pgv-java-stub/src/test/java/io/envoyproxy/pgv"
cp "/tests/java/pgv-java-stub/src/test/java/io/envoyproxy/pgv/ReflectiveValidatorIndexTest.java" "java/pgv-java-stub/src/test/java/io/envoyproxy/pgv/ReflectiveValidatorIndexTest.java"
mkdir -p "java/pgv-java-stub/src/test/proto"
cp "/tests/java/pgv-java-stub/src/test/proto/embedded.proto" "java/pgv-java-stub/src/test/proto/embedded.proto"

# Run the specific test file for this PR (only in pgv-java-stub module)
cd java/pgv-java-stub && mvn test -Dtest=ReflectiveValidatorIndexTest
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

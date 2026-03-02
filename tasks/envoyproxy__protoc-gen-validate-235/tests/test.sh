#!/bin/bash

cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "java/pgv-java-stub/src/test/java/io/envoyproxy/pgv"
cp "/tests/java/pgv-java-stub/src/test/java/io/envoyproxy/pgv/ExplicitValidatorIndexTest.java" "java/pgv-java-stub/src/test/java/io/envoyproxy/pgv/ExplicitValidatorIndexTest.java"
mkdir -p "java/pgv-java-stub/src/test/java/io/envoyproxy/pgv"
cp "/tests/java/pgv-java-stub/src/test/java/io/envoyproxy/pgv/ReflectiveValidatorIndexTest.java" "java/pgv-java-stub/src/test/java/io/envoyproxy/pgv/ReflectiveValidatorIndexTest.java"

# Run the specific test files for this PR (only in pgv-java-stub module)
cd java/pgv-java-stub && mvn test -Dtest=ExplicitValidatorIndexTest,ReflectiveValidatorIndexTest
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

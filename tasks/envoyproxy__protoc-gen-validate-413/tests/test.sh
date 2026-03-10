#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/generation/multi_file_java_test"
cp "/tests/generation/multi_file_java_test/BUILD" "tests/generation/multi_file_java_test/BUILD"
mkdir -p "tests/harness"
cp "/tests/harness/BUILD" "tests/harness/BUILD"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/BUILD" "tests/harness/cases/BUILD"
mkdir -p "tests/harness/cases/other_package"
cp "/tests/harness/cases/other_package/BUILD" "tests/harness/cases/other_package/BUILD"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/BUILD" "tests/harness/executor/BUILD"
mkdir -p "tests/harness/go/main"
cp "/tests/harness/go/main/BUILD" "tests/harness/go/main/BUILD"

# PR #413 fixes Bazel build by selectively adding/removing gazelle comments and updating dependencies
# The fix should:
# 1. ADD "# gazelle:go_generate_proto false" to tests/generation/multi_file_java_test/BUILD
# 2. REMOVE "# gazelle:exclude harness.pb.go" from tests/harness/BUILD
# 3. ADD "# gazelle:go_generate_proto false" to tests/harness/cases/BUILD
# 4. REMOVE "# gazelle:exclude go" from tests/harness/cases/other_package/BUILD
# 5. Update dependency paths to use _gen suffix and simplify lists
# 6. REMOVE "# gazelle:exclude validate.pb.go" from validate/BUILD
# 7. Downgrade Bazel rules_go and gazelle versions, reorder dependencies

echo "Testing gazelle comments and dependency updates..." >&2

# Test 1: Check multi_file_java_test/BUILD HAS the gazelle comment
echo "Checking tests/generation/multi_file_java_test/BUILD..." >&2
if grep -q "# gazelle:go_generate_proto false" tests/generation/multi_file_java_test/BUILD; then
    echo "PASS: gazelle comment present in multi_file_java_test/BUILD" >&2
    has_mfjt=1
else
    echo "FAIL: gazelle comment missing in multi_file_java_test/BUILD" >&2
    has_mfjt=0
fi

# Test 2: Check tests/harness/BUILD does NOT have gazelle exclude comment
echo "Checking tests/harness/BUILD..." >&2
if ! grep -q "# gazelle:exclude harness.pb.go" tests/harness/BUILD; then
    echo "PASS: gazelle exclude comment correctly removed from tests/harness/BUILD" >&2
    has_harness=1
else
    echo "FAIL: gazelle exclude comment still present in tests/harness/BUILD" >&2
    has_harness=0
fi

# Test 3: Check tests/harness/cases/BUILD HAS the gazelle comment
echo "Checking tests/harness/cases/BUILD..." >&2
if grep -q "# gazelle:go_generate_proto false" tests/harness/cases/BUILD; then
    echo "PASS: gazelle comment present in tests/harness/cases/BUILD" >&2
    has_cases=1
else
    echo "FAIL: gazelle comment missing in tests/harness/cases/BUILD" >&2
    has_cases=0
fi

# Test 4: Check tests/harness/cases/other_package/BUILD does NOT have gazelle exclude
echo "Checking tests/harness/cases/other_package/BUILD..." >&2
if ! grep -q "# gazelle:exclude go" tests/harness/cases/other_package/BUILD; then
    echo "PASS: gazelle exclude comment correctly removed from other_package/BUILD" >&2
    has_other=1
else
    echo "FAIL: gazelle exclude comment still present in other_package/BUILD" >&2
    has_other=0
fi

# Test 5: Check tests/harness/cases/BUILD uses _gen suffix (simplified dependencies)
echo "Checking tests/harness/cases/BUILD dependencies..." >&2
if grep -q "@com_github_golang_protobuf//ptypes:go_default_library_gen\"," tests/harness/cases/BUILD && \
   ! grep -q "@com_github_golang_protobuf//ptypes/duration:go_default_library\"," tests/harness/cases/BUILD; then
    echo "PASS: dependencies use _gen suffix in tests/harness/cases/BUILD" >&2
    has_cases_deps=1
else
    echo "FAIL: dependencies not using _gen suffix in tests/harness/cases/BUILD" >&2
    has_cases_deps=0
fi

# Test 6: Check tests/harness/cases/other_package/BUILD uses _gen suffix
echo "Checking tests/harness/cases/other_package/BUILD dependencies..." >&2
if grep -q "@com_github_golang_protobuf//ptypes:go_default_library_gen\"," tests/harness/cases/other_package/BUILD && \
   ! grep -q "@com_github_golang_protobuf//ptypes:go_default_library\"," tests/harness/cases/other_package/BUILD; then
    echo "PASS: dependencies use _gen suffix in other_package/BUILD" >&2
    has_other_deps=1
else
    echo "FAIL: dependencies not using _gen suffix in other_package/BUILD" >&2
    has_other_deps=0
fi

# Test 7: Check tests/harness/executor/BUILD uses _gen and wkt paths
echo "Checking tests/harness/executor/BUILD dependencies..." >&2
if grep -q "@com_github_golang_protobuf//ptypes:go_default_library_gen\"," tests/harness/executor/BUILD && \
   grep -q "@io_bazel_rules_go//proto/wkt:duration_go_proto\"," tests/harness/executor/BUILD && \
   grep -q "@io_bazel_rules_go//proto/wkt:timestamp_go_proto\"," tests/harness/executor/BUILD; then
    echo "PASS: dependencies use _gen and wkt paths in tests/harness/executor/BUILD" >&2
    has_executor=1
else
    echo "FAIL: dependencies not correctly set in tests/harness/executor/BUILD" >&2
    has_executor=0
fi

# Test 8: Check tests/harness/go/main/BUILD uses _gen suffix
echo "Checking tests/harness/go/main/BUILD dependencies..." >&2
if grep -q "@com_github_golang_protobuf//ptypes:go_default_library_gen\"," tests/harness/go/main/BUILD && \
   ! grep -q "@com_github_golang_protobuf//ptypes:go_default_library\"," tests/harness/go/main/BUILD; then
    echo "PASS: dependencies use _gen suffix in tests/harness/go/main/BUILD" >&2
    has_main=1
else
    echo "FAIL: dependencies not using _gen suffix in tests/harness/go/main/BUILD" >&2
    has_main=0
fi

# Test 9: Check Makefile does NOT have buildozer commands (these files are NOT copied from /tests)
echo "Checking Makefile for buildozer commands..." >&2
if ! grep -q "buildozer 'replace deps @com_github_golang_protobuf//ptypes:go_default_library_gen" Makefile; then
    echo "PASS: buildozer commands removed from Makefile" >&2
    has_makefile=1
else
    echo "FAIL: buildozer commands still present in Makefile" >&2
    has_makefile=0
fi

# Test 10: Check bazel/repositories.bzl uses upgraded rules_go version
echo "Checking bazel/repositories.bzl for rules_go version..." >&2
if grep -q "rules_go-v0.25.0" bazel/repositories.bzl || \
   grep -q "v0.25.0/rules_go-v0.25.0.tar.gz" bazel/repositories.bzl; then
    echo "PASS: rules_go upgraded to v0.25.0 in bazel/repositories.bzl" >&2
    has_rules_go=1
else
    echo "FAIL: rules_go not upgraded to v0.25.0 in bazel/repositories.bzl" >&2
    has_rules_go=0
fi

# Test 11: Check bazel/dependency_imports.bzl uses specific Go version
echo "Checking bazel/dependency_imports.bzl for Go toolchain version..." >&2
if grep -q 'version = "1.15.6"' bazel/dependency_imports.bzl; then
    echo "PASS: Go toolchain pinned to 1.15.6 in bazel/dependency_imports.bzl" >&2
    has_go_version=1
else
    echo "FAIL: Go toolchain not pinned to 1.15.6 in bazel/dependency_imports.bzl" >&2
    has_go_version=0
fi

# All checks must pass
if [ $has_mfjt -eq 1 ] && [ $has_harness -eq 1 ] && [ $has_cases -eq 1 ] && \
   [ $has_other -eq 1 ] && [ $has_cases_deps -eq 1 ] && [ $has_other_deps -eq 1 ] && \
   [ $has_executor -eq 1 ] && [ $has_main -eq 1 ] && [ $has_makefile -eq 1 ] && \
   [ $has_rules_go -eq 1 ] && [ $has_go_version -eq 1 ]; then
    echo "PASS: All PR #413 gazelle comments and dependency updates are present" >&2
    test_status=0
else
    echo "FAIL: Some PR #413 changes are missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

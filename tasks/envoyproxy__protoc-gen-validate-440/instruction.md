Running the validation harness via `bazel test //tests/...` is currently not practical because the harness is designed to be invoked with `bazel run` plus manual arguments, and it doesn’t integrate cleanly with Bazel’s standard test sharding mechanism. As a result, tests either don’t run under `bazel test` as expected or cannot be efficiently parallelized/sharded across CPU cores.

The test executor binary must be runnable as a Bazel test target for each validator language (at least C++, Java, and Python), so that `bazel test //tests/...` executes the full harness without requiring `bazel run` with ad-hoc arguments. The executor must accept a language-selection flag (for example `-cc`, `-java`, `-python`) and run only that harness’s test suite when invoked with that flag.

In addition, the executor must support Bazel test sharding so that a single language’s test suite can be split across multiple Bazel shards. When Bazel provides the sharding environment variables `TEST_TOTAL_SHARDS` and `TEST_SHARD_INDEX`, the executor should run only the subset of test cases belonging to that shard (with a stable partitioning of the overall test case list). To be recognized by Bazel as shard-aware, the executor must also create or modify the file identified by `TEST_SHARD_STATUS_FILE` when sharding variables are present.

Expected behavior:
- Invoking the executor with a single language flag runs that language’s harness and exits with status code 0 only if all executed test cases succeed.
- If any executed test case fails, the executor exits with a non-zero status code.
- The executor can run multiple test cases concurrently using a configurable `-parallelism` flag; passing a non-positive value should be treated as an error.
- When sharding is enabled via `TEST_TOTAL_SHARDS`/`TEST_SHARD_INDEX`, only the shard’s slice of the test case list is executed, and `TEST_SHARD_STATUS_FILE` is created/touched to indicate sharding support.
- If the sharding variables are missing or malformed, the executor should default to running the full test case list rather than crashing.

Actual behavior to fix:
- The harness cannot be reliably exercised via `bazel test //tests/...` without manual `bazel run` invocation patterns.
- The executor does not correctly (or at all) honor Bazel’s standard sharding environment, so large suites cannot be split across shards, making CI slower and preventing parallel shard execution.
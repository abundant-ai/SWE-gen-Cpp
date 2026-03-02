Catch2 currently cannot split a test run into shards suitable for Bazel-style test sharding. Add first-class sharding support so that the set of selected tests (after applying all filters/order/seed, etc.) can be evenly divided into N shards, and only shard K is listed/executed for a given invocation.

Introduce configuration fields accessible through the session configuration data and runtime config:
- `Config::shardCount()` and `Config::shardIndex()` getters
- corresponding mutable values in `Session::configData()` (e.g., `configData().shardCount` and `configData().shardIndex`) so users can override them programmatically after parsing command line arguments.

Add command line options:
- `--shard-count <N>` with default `1`
- `--shard-index <K>` with default `0`

Expected behavior:
- Sharding is applied after the final list of test cases to consider has been created (i.e., after all filters are resolved, and after ordering/randomization has been applied), so that each shard runs a contiguous slice of that final ordered list.
- Sharding must affect both listing tests (`--list-tests`, and similar listing/reporting modes) and executing tests, so that each shard sees only its own subset.
- The split must be as even as possible: earlier shards may contain at most 1 more test than later shards when the total is not divisible by `shardCount`.
- Provide a reusable function `Catch::createShard(container, shardCount, shardIndex)` (used internally and available for validation) that returns the subrange corresponding to the shard. For a container `[0,1,2,3,4,5,6]`, shard sizes should be distributed as:
  - `shardCount=2` -> sizes `[4,3]`
  - `shardCount=3` -> sizes `[3,2,2]`
  - `shardCount=4` -> sizes `[2,2,2,1]`
  - `shardCount=5` -> sizes `[2,2,1,1,1]`
  - `shardCount=6` -> sizes `[2,1,1,1,1,1]`
  - `shardCount=7` -> sizes `[1,1,1,1,1,1,1]`
  and the shard contents must preserve the original order and be contiguous slices.

Validation and error reporting:
- If `shardIndex >= shardCount`, execution/listing must fail with a clear diagnostic. The message must include the text:
  "The shard count (X) must be greater than the shard index (Y)"
  where `X` is the shard count and `Y` is the shard index.

Integration expectations:
- When running the same binary multiple times with identical seed/order/filter options but different shard indices (from `0` to `shardCount-1`) and the same `shardCount`, the union of test names across shards must exactly match the unsharded list (no missing tests, no duplicates), and the concatenation of shard lists must match the unsharded order.
- Executing tests under sharding must run exactly the tests listed for that shard, and the XML reporter output should contain only those test cases.

The end result should allow a runner to set sharding via command line or via environment-driven overrides (e.g., reading `TEST_TOTAL_SHARDS` and `TEST_SHARD_INDEX` into `session.configData()`), and have Catch2 correctly list/execute only the appropriate shard.
Catch2 currently lacks first-class support for test sharding (splitting the set of selected tests across multiple invocations of the same test binary). Add sharding support so that users can run the same test executable multiple times with a shared shard count and differing shard indices, and each run will execute (or list) only its portion of the overall test set.

Introduce two configuration values, accessible via `Config::shardCount()` and `Config::shardIndex()`, that control sharding behavior. Sharding must be applied after the final list of tests to run has been constructed (i.e., after all filters/tags have been applied and after ordering/randomization is decided), and it must affect both normal execution and listing modes (`--list-tests`).

Provide a utility function `Catch::createShard(container, shardCount, shardIndex)` that returns the subrange of items belonging to the given shard. The sharding must split items as evenly as possible while preserving the original order. For example, with 7 items and `shardCount=4`, shard sizes must be `[2,2,2,1]` and each shard must contain the corresponding contiguous segment of the original sequence. More generally, shards should be contiguous partitions whose sizes differ by at most 1, with earlier shards getting the larger sizes when the division is uneven.

Add command-line support for setting shard parameters (e.g., `--shard-count` and `--shard-index`, or equivalent) and ensure they are reflected in the session/config so that embedding applications can also set them via `session.configData()`.

Invalid shard parameters must be rejected with a clear error message. In particular, when `shardIndex >= shardCount`, running the test binary must fail and print exactly:

`The shard count (X) must be greater than the shard index (Y)`

(where `X` and `Y` are the provided values).

Expected behavior examples:
- With `shardCount=1` and `shardIndex=0`, the behavior is identical to today: all selected tests are listed/executed.
- With `shardCount=N>1`, the union of tests listed/executed across shard indices `[0..N-1]` must equal the full selected test list, with no duplicates or omissions, and the global order must be preserved when concatenating shard outputs in shard-index order.
- Sharding must work the same way for listing and execution, so `--list-tests` under sharding lists only the tests for that shard.

Implement the necessary plumbing so this works end-to-end through Catch2’s session/configuration, discovery/listing, and execution pipeline.
The multi-language validation harness runner is incorrectly summing test results across harnesses (go/cc/java/python/external). When at least one harness reports a skipped/allowed-failure result for a given test case, failures from other harnesses for that same test case can be incorrectly ignored, causing the overall run to pass when it should fail.

This shows up in scenarios where one harness (e.g., the C++ harness) marks specific cases as skipped/allowed failure, while another harness (e.g., Python or Java) actually fails the same case (returns a validity result that disagrees with the expected `tc.Valid`). In these situations, the executor currently treats the presence of a skip/allowed-failure as if it “covers” the test case globally, and the failure from the other harness is not counted.

The worker/executor logic needs to report and aggregate results per-harness per-test-case, not only per-test-case. Concretely:

- Executing a `TestCase` against multiple `Harness` implementations must produce an outcome that preserves each harness’s result independently.
- A harness reporting an allowed failure / skip must not prevent a different harness’s failure from being surfaced and counted as a failure.
- If any harness has an internal error (e.g., `res.Error == true` or the harness execution returns an error), that must be treated as a failure regardless of other harnesses.
- If any harness returns a validity outcome where `res.Valid != tc.Valid` and `res.AllowFailure` is false, the overall run must be considered failed even if another harness returned `res.AllowFailure == true` for the same test case.
- Only when all harnesses either (a) match the expected validity, or (b) disagree but explicitly set `AllowFailure` for that harness, should the test case be treated as non-failing overall.

This behavior should be implemented through the existing execution entry points used by the harness executor, including `Work(...)` and the per-test-case execution function (e.g., `execTestCase(...)`), and must ensure the final failure count reflects failures from any harness even in the presence of skips from other harnesses.

Example of the incorrect behavior to fix:

- For a particular `TestCase` where `tc.Valid == true`:
  - C++ harness returns `Valid == false` with `AllowFailure == true` (meaning “skip/allowed failure”)
  - Python harness returns `Valid == false` with `AllowFailure == false`

Expected: the overall run should fail because Python produced a real failure.
Actual: the overall run is incorrectly treated as non-failing because the skipped/allowed failure from C++ causes the Python failure to be ignored.
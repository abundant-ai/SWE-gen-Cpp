There is currently no supported way to generate benchmark argument sets from the cartesian product of explicit value lists. Users must either write many repetitive `->Args({...})` calls, or use `->Ranges({...})` which only supports generating sequences based on min/max and a multiplier and doesn’t allow selecting specific values per dimension.

Add a new public method on the benchmark registration interface that can generate arguments from the cartesian product of provided vectors. The API should be callable in the same fluent style as existing argument builders (like `->Args(...)` and `->Ranges(...)`).

Required behavior:
- Provide a method named `CartesianProduct` (public interface) that accepts a collection of value lists (e.g., `{{1, 2, 3}, {10}, {6, 12, 24, 36}}`).
- Register one benchmark run for every combination of one value taken from each inner list, in the natural nested-loop order (first list varies slowest, last list varies fastest). For example:
  ```cpp
  BENCHMARK(BM_SetInsert)
      ->CartesianProduct({{1, 2, 3}, {10}, {6, 12, 24, 36}});
  ```
  must be equivalent to registering `->Args({1,10,6})`, `->Args({1,10,12})`, `->Args({1,10,24})`, `->Args({1,10,36})`, then the same for `2`, then the same for `3`.
- The method must integrate with existing argument registration so it can be mixed with other calls in the chain. For example, this sequence must register exactly these argument tuples (and no others):
  - First an explicit tuple `({0, 100, 2000, 30000})`
  - Then all combinations from the product of `{{1, 2}, {15}, {3, 7, 10}, {8, 9}}`
  - Then an explicit tuple `({4, 5, 6, 11})`
  Each produced run should expose the values via `state.range(0)`, `state.range(1)`, etc., matching the tuple used to register that run.

Additionally, ensure the existing `Ranges(...)` functionality uses the same cartesian-product logic internally (so behavior stays correct while avoiding duplicate implementations). This refactor must not change the observable set of argument tuples produced by `Ranges(...)` other than maintaining the same established order and coverage.

If the cartesian product inputs are empty or contain empty inner lists, the behavior should be well-defined (either produce no additional argument sets or handle gracefully without crashes), consistent with how other argument-generation APIs behave when given invalid/degenerate input.
The benchmark library currently supports at most two argument ranges for a benchmark (often referred to as range_x and range_y). This is insufficient for benchmarks that need to sweep over 3+ independent parameters.

Add support for defining and using multiple ranges for a single benchmark run.

Users must be able to register benchmarks with:

- A list of explicit arguments via `Args({a, b, c, ...})`.
- A list of multiple ranges via `Ranges({{lo1, hi1}, {lo2, hi2}, {lo3, hi3}, ...})`, optionally combined with `RangeMultiplier(m)`.
- Mixing multi-range generation with explicit argument tuples, e.g. calling `Ranges(...)` and also adding a specific tuple via `Args({7, 6, 3})`.

At runtime, benchmark code must be able to access each parameter via `benchmark::State::range(i)` for any valid index `i` used by the registration (not limited to 0 and 1). For example, if a benchmark is registered with three ranges, `state.range(0)`, `state.range(1)`, and `state.range(2)` must all be valid and return the values for that particular run.

The multi-range expansion must enumerate the cartesian product of all provided ranges (after applying `RangeMultiplier` where applicable) and run the benchmark for each generated tuple. For instance, registering with `RangeMultiplier(2)` and `Ranges({{1,2}, {3,7}, {5,15}})` must generate runs covering:

- First dimension: 1, 2
- Second dimension: 3, 4, 7
- Third dimension: 5, 8, 15

so that combinations like (1,3,5), (2,7,15), etc. are all produced. Additionally, explicitly provided argument tuples (e.g., (7,6,3)) must also be included as separate runs in addition to the generated cartesian product.

Expected behavior:

- Benchmarks using fixtures and threading must continue to work correctly while using `state.range(i)`.
- `state.range(i)` must return stable, correct values for the current run so that code like `state.SetItemsProcessed(state.range(0));` and computations involving multiple indices (e.g. `state.range(0) * state.range(1) * state.range(2)`) behave correctly.
- Existing single-argument usage (`Arg(x)`, `Range(lo, hi)`, `DenseRange(lo, hi)`) must remain compatible and unchanged in behavior.

Currently, attempts to define or consume more than two ranges either cannot be expressed via the API or do not produce the required set of runs and/or do not allow accessing the extra dimensions through `state.range(i)`. Implement the multi-range feature so these scenarios work as described.
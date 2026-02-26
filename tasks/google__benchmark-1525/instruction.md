The command-line flag `--benchmark_min_time` currently only accepts a numeric value interpreted as a minimum number of seconds to run a benchmark. It needs to be extended to support two explicit forms that match the internal benchmark API:

1) `--benchmark_min_time=<integer>x` to specify an exact number of iterations to run.

2) `--benchmark_min_time=<float>s` to specify the minimum number of seconds to run (explicit seconds suffix). The existing no-suffix form (e.g. `--benchmark_min_time=4`) must continue to work and mean the same thing as `4s`.

A parsing function named `benchmark::internal::ParseBenchMinTime(...)` is responsible for interpreting the flag value. It must accept the new `x` and `s` suffixes and reject malformed inputs. In debug builds where checks/assertions are enabled, malformed inputs must terminate with an error message of the form:

`Malformed seconds value passed to --benchmark_min_time: `<VALUE>``

Examples of values that must be rejected include: `abc`, `123ms`, `1z`, and `1hs`.

When `--benchmark_min_time=<NUM>x` is provided (for example `--benchmark_min_time=4x`), running a benchmark via `benchmark::RunSpecifiedBenchmarks(...)` must execute exactly `<NUM>` iterations for the selected benchmark, and the reported run must show `iterations == <NUM>`.

When `--benchmark_min_time=<NUM>` (no suffix) or `--benchmark_min_time=<NUM>s` is provided (for example `4` or `4.0s`), the benchmark run configuration reported to a `benchmark::ConsoleReporter` (via its `ReportRunsConfig(double min_time, bool has_explicit_iters, IterationCount iters)` callback) must reflect `min_time == <NUM>` (with normal floating-point tolerance).

Overall expected behavior:
- Accept `N` and `Ns` as seconds (float allowed for the `s` form).
- Accept `Nx` as an iteration count (must be an integer).
- Reject any other suffixes or malformed formats and emit the exact error message shown above in debug/check-enabled builds.
- Ensure the parsed result correctly influences benchmark execution so that iteration-limited runs and time-limited runs behave as specified.
Benchmark repetition execution order is incorrect when random interleaving is enabled.

Google Benchmark supports running a benchmark multiple times via `--benchmark_repetitions`. Normally, each benchmark instance (including each argument/range expansion like `BM_Foo/64`, `BM_Foo/80`, etc.) runs its repetitions in a grouped, deterministic order.

A new mode is intended: when `--benchmark_enable_random_interleaving=true`, repetitions should be executed in a randomized interleaving across the set of benchmarks selected by `--benchmark_filter`. The goal is to reduce run-to-run variance by avoiding running all repetitions of the same benchmark back-to-back.

Currently, enabling random interleaving does not reliably produce interleaving behavior, and/or breaks expected behavior around repetitions and benchmark expansion. The runner must satisfy all of the following:

- When `--benchmark_enable_random_interleaving` is not set (or is false), execution order must remain stable and deterministic: benchmarks expanded from a single registration (via `Arg`, `Args`, `Range`, etc.) should execute once each in their normal order.
- When `--benchmark_repetitions=N` and random interleaving is disabled, each expanded benchmark (e.g., `BM_Match1/64`) must execute exactly N times consecutively before moving to the next expanded benchmark.
- When `--benchmark_enable_random_interleaving=true` and `--benchmark_repetitions` is large (e.g., 100) while filtering down to a small set of expanded benchmarks (e.g., only `BM_Match1/64` and `BM_Match1/80`), the execution stream must contain exactly N total executions of each expanded benchmark, but the ordering across repetitions should be mixed such that:
  - It is not simply `64` repeated N times followed by `80` repeated N times.
  - Across the run, both benchmarks should appear throughout the sequence (i.e., repetitions are actually interleaved rather than grouped).
  - The ordering should be randomized (not a fixed alternating pattern), while still guaranteeing the correct total counts per benchmark.

In addition, this mode must not ignore user-provided `--benchmark_repetitions`; the repetition count requested by the user must be honored exactly, with interleaving only affecting ordering.

Reproduction example:
- Register a benchmark with multiple argument expansions (like `Arg(1)`, `Arg(2)`, `Range(10, 80)`, etc.).
- Run with `--benchmark_filter` selecting a subset of expansions (for example, only the `/64` and `/80` variants).
- Set `--benchmark_repetitions=2` and confirm the default behavior is `64,64,80,80`.
- Then set `--benchmark_enable_random_interleaving=true --benchmark_repetitions=100` and confirm the output/side effects indicate 100 runs of `/64` and 100 runs of `/80`, and that their appearances are interspersed rather than grouped.

The fix should ensure that random interleaving changes only the execution order across repetitions, while preserving benchmark selection (`--benchmark_filter`), argument expansion semantics, and exact repetition counts.
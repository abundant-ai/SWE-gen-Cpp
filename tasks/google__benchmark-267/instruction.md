Running benchmarks with repetitions currently prints every individual repetition result and then prints aggregate statistics (mean/stddev). This output is often too verbose when users only want the aggregate summary.

Add support for a boolean setting that controls whether per-repetition results are reported. Introduce a command-line flag `--benchmark_report_repetitions={true|false}` and a corresponding public API `Benchmark::ReportRepetitions(bool)`.

Expected behavior:
- Default behavior must remain unchanged: when a benchmark is run with repetitions, the output includes all individual repetition lines and also includes the final aggregate statistics.
- When `--benchmark_report_repetitions=false` is provided, repeated benchmarks must suppress the individual repetition reports and only emit the aggregate summary for that benchmark (the mean/stddev line(s)).
- When `--benchmark_report_repetitions=true` is provided, behavior must match the default (all repetitions plus aggregates).
- When `Benchmark::ReportRepetitions(false)` is called, it must have the same effect as the command-line flag being set to false (suppress per-repetition output). When set to true, it must re-enable per-repetition output.
- The behavior must apply consistently across supported output formats (console, JSON, CSV): disabling repetition reporting should remove per-run entries and keep only the aggregate information.

If the flag is set to false, users should no longer see multiple lines/entries corresponding to each repetition; they should only see the aggregate result for the repeated benchmark. Conversely, enabling it (or leaving it unset) should continue to show the individual runs as before.
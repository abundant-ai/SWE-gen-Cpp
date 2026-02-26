Google Benchmark currently does not provide a supported way to attach arbitrary, user-defined key/value metadata to a benchmark run and have that metadata show up in exported results. This makes it difficult to store provenance such as a build version, git SHA, or environment identifier inside JSON/CSV outputs so results can be reproduced later.

Add support for a command-line flag named `--benchmark_context` that can be provided multiple times to supply custom context entries as key/value pairs. These values must be parsed as key-value flags (i.e., `--benchmark_context=key=value`) and collected into the benchmark’s run context.

When `--benchmark_context` is provided, the supplied key/value pairs must be included in the context emitted by reporters (at minimum, the base reporter interface should receive and output these fields so that formats like JSON/CSV can include them alongside the existing context fields).

The command-line parsing must correctly handle key/value flags in general, including:

- Accepting `--flag=key=value` where `key` and `value` are non-empty strings.
- Allowing multiple occurrences of `--benchmark_context=...` and emitting all pairs.
- Handling invalid forms gracefully (for example, missing `=` between key and value, empty key, or empty value) in a consistent way (either ignore with a clear error/diagnostic or reject with an error), rather than silently producing incorrect context.

Example expected behavior:

- Running a benchmark with `--benchmark_context=build=1.2.3 --benchmark_context=commit=abc123` should result in exported output that contains context entries `build: "1.2.3"` and `commit: "abc123"` in the run’s context metadata.

Implement the necessary public-facing behavior so that callers can rely on `--benchmark_context` for per-run custom context fields, and ensure the key/value flag parsing works across platforms (including Windows) and does not break existing boolean/environment flag behavior such as `BoolFromEnv(...)`.
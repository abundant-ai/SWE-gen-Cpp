The benchmark library accepts a command-line verbosity option via `--v=<int>` (or equivalent) during `benchmark::Initialize(&argc, argv)`, but benchmark programs cannot query the resulting verbosity level through the public API without re-parsing argv themselves or relying on internal symbols.

Add a public function `int32_t benchmark::GetBenchmarkVerbosity()` that returns the current verbosity level as set by the `--v` command-line flag after initialization.

When a program is invoked with `--v=42`, then calls `benchmark::Initialize(&argc, argv)`, calling `benchmark::GetBenchmarkVerbosity()` must return `42`. If the library reports a different value, programs should surface an error like:

`Seeing different value for flags. GetBenchmarkVerbosity() returns [X] expected flag=[42]`

The returned value must accurately reflect whatever value the library accepted for `--v` (including the library’s existing integer conversion and range checking behavior), and it should be accessible to user code via the public benchmark header API after `Initialize` has processed arguments.
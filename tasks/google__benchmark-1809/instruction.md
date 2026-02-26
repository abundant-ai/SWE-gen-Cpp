Add a public API that lets external tools register a custom profiler to wrap benchmark execution, similar in spirit to the existing MemoryManager hook.

Currently, users cannot provide a profiler implementation that is invoked automatically around benchmark runs (e.g., to start/stop a tracing tool like DynamoRIO). The framework should expose a base class and registration function so that a binary can install a profiler object before running benchmarks, and the library will call into it at the correct times.

Implement a class named `benchmark::ProfilerManager` that tools can subclass. It must provide two overridable lifecycle methods:
- `AfterSetupStart()`
- `BeforeTeardownStop()`

Expose a registration function `benchmark::RegisterProfilerManager(benchmark::ProfilerManager*)` that sets the active profiler manager (or clears it when passed `nullptr`).

When a profiler manager is registered, the benchmark runner must invoke `AfterSetupStart()` at the start of running benchmarks (after benchmark setup is complete), and invoke `BeforeTeardownStop()` at the end of running benchmarks (before teardown begins). These calls must occur in a dedicated pass that wraps running the benchmark(s), in the same overall style as how memory management hooks wrap benchmark execution, so that the profiler measures the benchmark run rather than framework initialization.

The API must be safe to use from a normal benchmark `main()` that registers a profiler manager, runs the benchmarks, and then unregisters it. Registering a profiler manager must not change benchmark results formatting or break console/JSON/CSV outputs; existing benchmark output for a simple benchmark (e.g., `BM_empty`) should remain valid while the profiler callbacks are invoked behind the scenes.
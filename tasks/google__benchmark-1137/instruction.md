Google Benchmark currently emits a fixed “context” block in outputs like JSON/CSV, but there is no supported API for users to attach their own key/value metadata (for example, a build version or git SHA) so that exported results are self-describing and reproducible. Users want to add arbitrary custom context fields that show up alongside the existing context data in benchmark outputs.

Implement a public API that allows adding custom context entries as string key/value pairs before running benchmarks. The API should be usable from normal benchmark code (similar in spirit to other global configuration functions), and it must store the provided entries in a global context map that is included when producing benchmark reports.

Behavior requirements:
- Provide a function named `AddCustomContext(const std::string& key, const std::string& value)` in the `benchmark` namespace.
- Calling `AddCustomContext(k, v)` should record the pair into the global benchmark context so it is emitted in the report outputs.
- If `AddCustomContext` is called multiple times with the same `key`, the latest `value` should be the one present in the final context.
- Adding custom context must not break existing context generation; the final context should include both built-in fields (e.g., CPU/system fields) and the user-provided ones.
- The implementation must be safe to call before `RunSpecifiedBenchmarks()` and should not require users to manually manage any internal global pointers/objects.

Example usage that should work:
```cpp
benchmark::AddCustomContext("build_version", "1.2.3");
benchmark::AddCustomContext("git_sha", "abc123");
benchmark::RunSpecifiedBenchmarks();
```
After running, the generated output’s context section should contain at least `build_version: "1.2.3"` and `git_sha: "abc123"` in addition to the standard context fields.
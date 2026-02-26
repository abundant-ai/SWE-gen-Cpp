Users cannot currently override the displayed name of a registered benchmark, which makes it difficult to post-process results when using fixtures/templates or when wanting more descriptive names. Add support for setting a custom benchmark name via a fluent API on the benchmark registration object.

When registering a benchmark, calling `Name(const std::string&)` should set the benchmark’s display name. This should work in combination with other registration modifiers like `MinTime(...)`, `Repetitions(...)`, and `TimeUnit(...)`.

For example, code like:

```cpp
BENCHMARK_REGISTER_F(MyFixture, Bar)->Name("MyFixture/double")->MinTime(5);
```

should produce output where the benchmark name is based on the custom name, and any automatically appended qualifiers (such as the min-time annotation) are still applied. In console output, the leftmost benchmark identifier should start with `MyFixture/double` and include the min-time suffix (e.g. `.../min_time:5.000`). In structured outputs, the benchmark entry’s `name` and `run_name` fields should reflect the custom name rather than the original function/fixture-generated name.

Currently, even if a name override is attempted (or there is no API to do so), outputs continue to use the original generated benchmark name. Implement the `Name()` API so it correctly updates the internally stored benchmark name (via an internal setter such as `SetName()` if present), and ensure all reporters (console, JSON, CSV) consistently use this overridden name for benchmark identification.
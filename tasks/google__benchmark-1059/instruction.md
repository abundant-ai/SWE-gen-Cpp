Projects that compile C++ code with `-Wsuggest-override` (and treat warnings as errors via `-Werror`) fail to build when using the library’s extensibility points (fixtures, reporters, memory managers), because derived classes override virtual methods but the library does not provide a consistent way to mark those overrides with the C++11 `override` keyword.

The library should provide a public macro named `BENCHMARK_OVERRIDE` that expands to the C++ `override` specifier when supported by the compiler (C++11 and later), and expands to nothing on compilers/configurations where `override` is not available. This macro must be usable in user code in the same places as `override` would be used: at the end of overriding virtual member function declarations.

After this change, user-defined subclasses should be able to write overrides like:

```cpp
class MyFixture : public benchmark::Fixture {
 public:
  void SetUp(const benchmark::State& state) BENCHMARK_OVERRIDE;
  void TearDown(const benchmark::State& state) BENCHMARK_OVERRIDE;
};

class MyReporter : public benchmark::ConsoleReporter {
 public:
  bool ReportContext(const Context& context) BENCHMARK_OVERRIDE;
  void ReportRuns(const std::vector<Run>& report) BENCHMARK_OVERRIDE;
};

class MyMemoryManager : public benchmark::MemoryManager {
 public:
  void Start() BENCHMARK_OVERRIDE;
  void Stop(Result* result) BENCHMARK_OVERRIDE;
};
```

Expected behavior: code like the above compiles cleanly under `-Wsuggest-override` and does not require users to suppress warnings or avoid `-Werror`.

Actual behavior: without an `override` specifier (or a macro that provides it), compilers emit `-Wsuggest-override` warnings for these overridden virtual methods, and builds that use `-Werror` fail.

Implement `BENCHMARK_OVERRIDE` as part of the library’s public API so it can be included via the main benchmark header and used by downstream projects when overriding virtual methods from `benchmark::Fixture`, `benchmark::ConsoleReporter` (and other reporters), and `benchmark::MemoryManager`.
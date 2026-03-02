When building Catch2 in C++17 mode using Clang 5 while linking against libstdc++ v5 (an older standard library that is missing some C++17 library features), compilation fails in the generators functionality.

The expected behavior is that Catch2 should still compile successfully in this environment: it should not assume that selecting C++17 implies the presence of a fully C++17-capable standard library. In particular, the generators utilities used via the `GENERATE(...)` macro and generator adapters (such as `values(...)`, `table<...>(...)`, `as<T>{} ...`, and random/range adapters) must remain usable without triggering compilation errors that rely on missing libstdc++ v5 library support.

Currently, enabling `-std=c++17` with Clang 5 and libstdc++ v5 causes compilation errors in the generator headers/implementation (errors typically appear as missing/unsupported standard library types or functions that are assumed to exist under C++17). The task is to update Catch2’s generator implementation so that it conditionally avoids using unsupported standard-library features when the compiler advertises C++17 but the standard library does not provide the corresponding facilities.

After the fix, code using nested generators and sections should compile and run, including:
- `auto i = GENERATE(1, 2, 3);`
- `auto j = GENERATE(values({ -3, -2, -1 }));`
- `auto str = GENERATE(as<std::string>{}, "a", "bb", "ccc");`
- `auto data = GENERATE(table<char const*, int>({...}));` (including the common workaround of providing explicit `std::tuple<...>` elements)

Structured bindings support should remain gated by feature detection (`__cpp_structured_bindings`), and using `table<...>(...)` in structured-binding form should continue to compile when structured bindings are available.

In short: make Catch2’s generators compile cleanly under the mixed environment “C++17 compiler + pre-C++17 libstdc++”, without regressing compilation or behavior on newer libstdc++/libc++ toolchains.
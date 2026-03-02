Building the library with C++14 currently fails even though the project documentation/build expectations indicate C++14 should be sufficient. In practice, the codebase uses C++17-only types (notably `std::string_view`), so compiling with `-std=c++14` produces errors such as:

```
error: no type named 'string_view' in namespace 'std'
```

The project needs to consistently require and enforce C++17 as the minimum supported C++ standard across its build configurations and compilation checks.

When users build the library (and its associated targets) with an explicit C++14 setting, the build should not fail later with missing-type errors from headers using `std::string_view`; instead, the build system and compilation configuration should ensure C++17 is selected as the default/required standard.

Additionally, there should remain a way to compile a small “C++11 mode” compilation check target that verifies the compiler is actually using C++11 when explicitly requested (e.g., via `-std=c++11` or the equivalent on MSVC), but the normal test/build configuration must use C++17 (e.g., `-std=c++17` or `/std:c++17`) and validate that the expected standard is in effect.

Expected behavior: standard builds/tests compile in C++17 mode by default/requirement, and users do not encounter `std::string_view` missing-type errors due to accidental C++14 compilation.

Actual behavior: builds can still be driven in C++14 mode despite C++17-only usage, leading to compile failures like the `std::string_view` error above.
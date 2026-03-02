When compiling a C++ program on Windows with MSVC (cl) that includes the library’s public header `nlohmann/json.hpp`, the compiler emits warnings like:

```
warning C4068: unknown pragma 'GCC'
```

This happens because the header contains `#pragma GCC ...` directives that are not understood by MSVC, and MSVC warns about unknown pragmas. Users expect including the header to compile cleanly on supported compilers without requiring local warning suppression.

Reproduction:

```cpp
#include "nlohmann/json.hpp"
int main() { return 0; }
```

Compiling with MSVC (e.g. `cl /EHsc main.cpp`) currently produces `warning C4068: unknown pragma 'GCC'`.

Expected behavior: Including `nlohmann/json.hpp` should not produce MSVC warning C4068 (or other avoidable MSVC warnings) under typical warning levels.

Actual behavior: MSVC warns about unknown `GCC` pragmas.

Fix the library headers so that compiler-specific `#pragma GCC ...` directives are not seen by MSVC (e.g., they should only apply when building with GCC/Clang where those pragmas are valid). After the change, the library and its unit tests should build with MSVC in a configuration where MSVC warnings are treated as errors (so any remaining C4068 or similar warnings would fail the build).
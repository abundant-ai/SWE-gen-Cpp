Using `FMT_COMPILE` with `fmt::join` fails to compile starting in v8.0.0 due to a const-correctness mismatch in the formatter used for `fmt::join_view`.

A minimal reproducer is:
```cpp
#include "fmt/core.h"
#include "fmt/compile.h"

int main() {
  unsigned char data[] = {0x1, 0x2};
  auto s = fmt::format(FMT_COMPILE("{:02x}"), fmt::join(data, ""));
}
```

Expected behavior: the code compiles and produces a string where each element of `data` is formatted according to the `{:02x}` spec and concatenated (e.g., "0102" for the example above).

Actual behavior: compilation fails on GCC with an error indicating that a `const fmt::formatter<fmt::join_view<...>>` is being used to call a non-const `format(...)` member function. The error is of the form:

```
error: passing ‘const fmt::formatter<fmt::join_view<...>, char, void>’ as ‘this’ argument discards qualifiers
```

`FMT_COMPILE` expands to a compiled-format path where formatting fields are treated as `const` during formatting. Formatting a `fmt::join_view` in this path must therefore work with a formatter whose `format` can be invoked on a const formatter instance (or otherwise be const-correct), while still honoring the element format specifiers (like `02x`) and supporting joining with the provided separator.

Fix the constness issue so that `fmt::format(FMT_COMPILE("{:02x}"), fmt::join(data, ""))` compiles successfully and formats correctly, without regressing runtime (non-compiled) formatting behavior for `fmt::join`.
Using `FMT_COMPILE` with `fmt::join` and a format specifier fails to compile due to a const-correctness issue in the compiled-format code path.

Reproduction:
```cpp
#include "fmt/core.h"
#include "fmt/compile.h"

int main() {
  unsigned char data[] = {0x1, 0x2};
  auto s = fmt::format(FMT_COMPILE("{:02x}"), fmt::join(data, ""));
}
```

Starting with fmt v8.0.0, this triggers a compilation error on GCC/Clang similar to:

"passing ‘const fmt::formatter<fmt::join_view<...>, char, ...>’ as ‘this’ argument discards qualifiers"

This indicates that, when formatting a `fmt::join_view` via a compiled format string, the compiled formatting machinery ends up calling `formatter<join_view<...>>::format(...)` on a `const formatter` even though the formatter’s `format` member function is not being treated as callable on a const instance.

`fmt::format(FMT_COMPILE(...), ...)` should compile and work the same way as runtime formatting for join views. In particular, formatting joined elements with a spec like `{:02x}` should compile and produce the expected string (for the example above, each byte formatted as two hex digits, concatenated without a separator).

Fix the compiled-format path so that `FMT_COMPILE` supports `fmt::join` with format specifiers without const-qualification compilation errors, while preserving existing behavior for other compiled formatting cases.
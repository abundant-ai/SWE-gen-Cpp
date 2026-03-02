Formatting `_BitInt` values fails on clang (clang >= 14 where `_BitInt` is supported) starting with fmt v10, even though it worked in fmt 9.x. A minimal example like:

```cpp
#include <fmt/format.h>

int main() {
  _BitInt(32) x = 42;
  auto s = fmt::format("{}", x);
}
```

fails to compile with an error like:

```
error: constexpr variable 'desc' must be initialized by a constant expression
```

This indicates that the internal compile-time format-argument descriptor computation cannot encode the argument type for `_BitInt`, so the argument is not being mapped to a supported built-in type category during compile-time argument processing.

`fmt::format` (and related formatting APIs that accept format strings and arguments) should compile and work when passed `_BitInt` values on clang versions that implement `_BitInt` (enable support for clang >= 14). `_BitInt` should be treated as an integer type for formatting purposes (signedness should follow the `_BitInt` type), so that formatting with `{}` produces the expected decimal representation and the compile-time descriptor remains a constant expression.

The regression was introduced when a previously broader fallback mapping for unknown arithmetic/integer-like types was narrowed, causing `_BitInt` to no longer match any type-mapping overload unambiguously. Ensure the type-mapping logic used for format argument classification has an unambiguous overload for `_BitInt` so that compile-time argument encoding succeeds and no constexpr initialization errors occur.
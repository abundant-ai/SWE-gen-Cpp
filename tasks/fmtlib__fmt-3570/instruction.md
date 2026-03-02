Formatting a single element of a space-efficient boolean container such as `std::vector<bool>` fails to compile because `operator[]` returns a proxy reference type (e.g., `std::vector<bool>::reference`) rather than `bool`. For example:

```cpp
#include <vector>
#include <fmt/core.h>

int main() {
  std::vector<bool> v = {false};
  fmt::print("{}", v[0]);
}
```

This should compile and print `false` (and print `true` when the element is `true`) without requiring the user to cast `v[0]` to `bool`.

Currently, the call fails at compile time because there is no suitable `fmt::formatter` for the proxy/bit-reference-like type returned by `std::vector<bool>::operator[]` (and similar proxy types), even though formatting a plain `bool` works.

Update the formatting library so that bit-reference-like proxy types that are convertible to `bool` can be formatted the same way as `bool` with the standard boolean formatter behavior. This should work with common formatting entry points such as `fmt::format("{}", value)` and `fmt::print("{}", value)` when `value` is such a proxy reference.

The behavior should be consistent with existing boolean formatting in fmt (e.g., default `{}` formatting producing `true`/`false`).
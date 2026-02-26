Formatting a single element of `std::vector<bool>` fails to compile because `operator[]` returns a proxy reference type (`std::vector<bool>::reference`) rather than a real `bool`. For example:

```cpp
#include <vector>
#include <fmt/core.h>

int main() {
  std::vector<bool> v = {false};
  fmt::print("{}", v[0]);
}
```

This should compile and print `false` (and similarly print `true` for `v[0] = true`). Instead, compilation fails because the library does not have a usable formatter for this proxy “bit reference” type and it isn’t treated as a `bool` value.

Update the formatting library so that “bit_reference-like” proxy types (such as `std::vector<bool>::reference`, and other similar bit-proxy reference types that are convertible to `bool`) can be formatted with the standard boolean formatting behavior. Calls like `fmt::format("{}", v[0])` and `fmt::print("{}", v[0])` must compile without requiring an explicit cast by the user.

The solution must not break formatting of ordinary ranges (including formatting `std::vector<bool>` as a range) and should ensure that a `std::vector<bool>::reference` formats the same way a `bool` does for normal format strings.
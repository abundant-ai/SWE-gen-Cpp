There is a compilation failure with Intel ICC 19.x when formatting certain view-like arguments through the ostream printing API, e.g. using `fmt::print(std::ostream&, ...)` with `fmt::group_digits()`.

Example:
```cpp
#include <fmt/format.h>
#include <fmt/ostream.h>
#include <sstream>

int main() {
  std::ostringstream errmsg;
  int age = 56;
  fmt::print(errmsg, "I am {} years old\n", fmt::group_digits(age));
}
```

With Intel ICC 19.1.3, this fails at compile time with a static assertion:

`static assertion failed with "Cannot format a const argument."`

The failure originates during argument packing for checked formatting: the argument store construction ends up treating a formattable argument (like `fmt::group_digits_view<int>`) as a `const` argument in a way that triggers the library’s “cannot format a const argument” guard, even though this usage should be supported.

The library should allow the above code to compile and format correctly on ICC 19.x, producing output equivalent to:

`I am 56 years old`

(with digit grouping applied as appropriate).

Fix the argument-building path used by ostream printing so it no longer triggers the const-argument static assertion on ICC 19.x. The solution should prefer the modern argument construction API (e.g., `fmt::make_format_args`) and remove reliance on the legacy checked-argument helper (`fmt::make_args_checked`) so that `fmt::print(std::ostream&, ...)` and related checked-formatting entry points work consistently across compilers.

Also ensure the C++20 module build/import scenario continues to compile cleanly after the removal of the legacy API (no missing symbols or unintended macro/namespace leaks).
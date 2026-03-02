Using compiled format strings with `FMT_COMPILE` currently fails to compile when calling `fmt::print` with chrono formatting, even though the same format works with a normal runtime format string.

For example, the following should compile and print a formatted `tm` timestamp:

```c++
#include <fmt/chrono.h>
#include <fmt/compile.h>

int main() {
  std::tm t = {};
  t.tm_year = 2010 - 1900;
  t.tm_mon = 6;
  t.tm_mday = 4;
  t.tm_hour = 12;
  t.tm_min = 15;
  t.tm_sec = 58;

  fmt::print(FMT_COMPILE("{:%Y-%m-%dT%H:%M:%S}"), t);
}
```

Expected behavior: `fmt::print(FMT_COMPILE("{:%Y-%m-%dT%H:%M:%S}"), t)` compiles successfully and produces the same output as `fmt::print("{:%Y-%m-%dT%H:%M:%S}", t)`.

Actual behavior: with current master, major compilers reject the `fmt::print` call when the format string is wrapped in `FMT_COMPILE(...)` and the argument uses chrono formatting (e.g., `std::tm` with `fmt/chrono.h`). The compiled-format path lacks an appropriate `fmt::print` overload or printing implementation for compiled format strings.

Implement support for calling `fmt::print` with compiled format strings so that it works for chrono types (including `std::tm`) and, more generally, behaves consistently with the runtime-format `fmt::print` API. The solution should ensure the compiled-format printing path ultimately writes the formatted result to the provided `std::FILE*` / stdout in the same way as the existing runtime `vprint`-based printing does, without requiring users to switch to `fmt::format` as a workaround.
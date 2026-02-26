Formatting `std::bitset<N>` with the fmt library regressed and no longer works as it used to when the type was implicitly formattable via its `operator<<(std::ostream&)`. As a result, code like:

```cpp
#include <bitset>
#include <string>
#include <fmt/std.h>

auto s = fmt::format("{}", std::bitset<8>(0b10101010));
```

should compile and produce the same textual representation as streaming the bitset to an `std::ostream` would (i.e., the standard `0`/`1` bit string for the bitset), but currently fails to format the value.

Make `std::bitset<N>` formattable again by providing proper `fmt::formatter` support for `std::bitset<N>` when users include the standard-library integration header (e.g., `fmt/std.h`). After the fix, `fmt::format("{}", some_bitset)` must compile and return the expected bit-string representation for any `N`. Formatting should work in the same situations where other std types supported by `fmt/std.h` work (e.g., as a direct argument to `fmt::format`).
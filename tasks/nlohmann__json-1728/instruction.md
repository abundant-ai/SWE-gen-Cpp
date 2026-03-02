A regression introduced around v3.7.0 causes undefined-behavior sanitizer (UBSan) builds to report a runtime error when parsing an empty std::string with nlohmann::json::parse().

Reproduction:

```cpp
#include "json.hpp"

int main() {
  std::string m = "";
  auto doc = nlohmann::json::parse(m);
}
```

When compiled with GCC or Clang using undefined-behavior sanitizing (e.g., `-fsanitize=undefined` and without recovery), running this program should terminate by throwing `nlohmann::detail::parse_error` with an error message indicating an unexpected end of input at line 1, column 1.

Instead, under UBSan the program reports a runtime error similar to:

```
runtime error: null pointer passed as argument 2, which is declared to never be null
```

This UBSan report indicates that the parse path for an empty `std::string` triggers undefined behavior (e.g., passing a null pointer to a library routine) rather than cleanly producing the expected `parse_error`. The behavior is inconsistent with earlier versions where the same input reliably resulted in a `parse_error`, and it is also inconsistent with parsing empty input from a `const char*`, which should likewise fail with `parse_error` rather than triggering sanitizer findings.

Fix the library so that calling `nlohmann::json::parse()` with an empty `std::string` does not produce UBSan findings and instead deterministically throws `nlohmann::detail::parse_error` as expected. Additionally, sanitizer-based builds should treat sanitizer findings as non-recoverable failures (so the issue cannot be ignored during CI) and provide enough runtime diagnostics (including stack traces where supported) to locate the offending call chain when a sanitizer issue does occur.
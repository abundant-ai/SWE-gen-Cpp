When building {fmt} as a static library and then linking it into a shared library (DSO) that exposes a function using compiled-format support, the final link can fail with an undefined symbol error:

undefined reference to `fmt::v7::detail::basic_data<void>::digits'

This happens in configurations that hide symbols by default (e.g., building a shared library with hidden visibility presets / hidden inline visibility) while linking against a static fmt build, and it was introduced by a recent change.

Reproduction scenario: build {fmt} as a static library (BUILD_SHARED_LIBS=OFF) with position-independent code enabled, then build a shared library that links to fmt and exports a function like:

```cpp
#include <fmt/compile.h>
#include <string>

__attribute__((visibility("default"))) std::string foo() {
  return fmt::format(FMT_COMPILE("foo bar {}"), 4242);
}
```

Then link an executable against that shared library and call `foo()`. The build should succeed and the executable should run, printing the formatted string (e.g., `foo bar 4242`).

Currently, the shared library link fails because the `fmt::v7::detail::basic_data<void>::digits` symbol is not being emitted/available in this static-into-shared setup. Update the library so that this symbol (and any other required compiled-format/static data referenced by `FMT_COMPILE` formatting code) is properly defined and linkable when {fmt} is built as a static library and consumed from a shared library with hidden default visibility.
spdlog currently supports being consumed via CMake, but it cannot be cleanly included and built as a Meson subproject. When a Meson-based application tries to add spdlog as a subproject and link against it, there is no supported Meson interface for obtaining an appropriate dependency object, and core build variants/features available in the CMake build are not consistently exposed.

Implement Meson build support so that a Meson project can vendor spdlog under a `subprojects/spdlog` directory and do:

```meson
sub = subproject('spdlog')
dep = sub.get_variable('spdlog_dep')
executable('main', ['main.cpp'], dependencies: [dep])
```

and then compile a program that includes and uses:

```cpp
#include <spdlog/spdlog.h>

int main() {
  spdlog::info("Hello World");
}
```

In addition to providing `spdlog_dep` for the normal library, the Meson integration must also expose a header-only dependency object (named `spdlog_headeronly_dep`) so consumers can choose either link-time library usage or header-only usage.

The Meson build must support building spdlog’s test executables in both configurations (normal and header-only). Optional features that depend on external system libraries must be handled gracefully: when `libsystemd` is available it should be linked and the systemd-related functionality should be built and tested; when `libsystemd` is not available the build must still succeed and simply skip that functionality.

Expected behavior:
- A Meson project can consume spdlog as a subproject and link successfully using `spdlog_dep`.
- A Meson project can consume the header-only variant via `spdlog_headeronly_dep`.
- The test suite can be built and run in both modes; the build should not fail on systems lacking optional dependencies such as `libsystemd`.

Actual behavior (before the change):
- Meson consumers have no supported subproject dependency variables to link against, and building/running the library and its tests via Meson is not supported, especially around optional dependency handling (e.g., systemd).
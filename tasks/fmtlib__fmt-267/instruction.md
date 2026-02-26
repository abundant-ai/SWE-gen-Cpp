After updating the project layout, downstream consumers must be able to use the library via either adding it as a subdirectory or via CMake’s find_package(), and in both cases the public headers must be includable as `#include "cppformat/format.h"`.

Currently, when a consumer project tries to build a simple executable that includes `cppformat/format.h` and links to the library target, the build can fail because the exported/propagated include directories and required compile definitions are not correctly attached to the CMake targets. The failure shows up as missing header errors for `cppformat/format.h` (or other public headers) when compiling a target that links against `cppformat` or `cppformat-header-only`, and/or as missing required compile-time configuration when building in header-only mode.

Fix the CMake configuration so that:

1) When a project does `add_subdirectory(<cppformat source>)` and then `target_link_libraries(app cppformat)`, the app can compile with `#include "cppformat/format.h"` without manually adding include directories.

2) When a project installs the library and then does `find_package(cppformat REQUIRED)` followed by `target_link_libraries(app cppformat)`, the app can compile with `#include "cppformat/format.h"` without manually adding include directories.

3) If a `cppformat-header-only` target is available, linking an application against it must also allow compiling with `#include "cppformat/format.h"` without additional include path tweaks, and must correctly propagate whatever compile definitions are required for header-only usage.

4) Header-only usage must remain safe across multiple translation units (i.e., two separate .cc/.cpp files both including `cppformat/format.h` should not produce duplicate symbol/link errors, and required configuration macros must be consistent).

5) Existing compile-time constraints should still behave correctly in header-only mode: certain invalid uses must intentionally fail to compile (e.g., passing `volatile char*` to `fmt::internal::MakeArg<char>`, using wide characters with narrow writers/format strings, and triggering `FMT_STATIC_ASSERT` conditions). The build system must not accidentally alter include paths/definitions in a way that makes these checks silently pass or fail incorrectly.

In short: make the new `cppformat/`-prefixed public header layout work reliably for both `add_subdirectory` and `find_package` consumers, ensuring correct include directory and compile definition propagation for both the compiled library target (`cppformat`) and the header-only target (`cppformat-header-only`).
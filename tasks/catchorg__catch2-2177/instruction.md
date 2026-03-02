Catch2’s public headers are not consistently self-sufficient: some headers only compile when included after other Catch2 headers, because they rely on transitive includes or declarations that are not directly provided. This causes problems for users who include individual headers in isolation, and it makes it hard to detect missing includes during development.

Add an optional build mode that generates and builds “surrogate translation units” (surrogate TUs) for Catch2 headers. A surrogate TU is a generated .cpp file whose entire contents is a single include of one Catch2 header (e.g. `#include <catch2/some_header.hpp>`). When enabled, the build should compile a surrogate TU for each main Catch2 header (excluding aggregate/helper headers such as `*_all.hpp`). If any header is not self-sufficient, building the surrogate TUs should fail at compile time, surfacing the missing include/declaration problem.

This surrogate TU compilation should be gated behind a dedicated CMake option (e.g. `CATCH_BUILD_SURROGATES`) so it does not affect default consumer builds, and it should be intended for development/testing usage (e.g. only available/meaningful when a development-build toggle is enabled). When the option is enabled, configuring should:

- Discover the set of Catch2 headers that should have surrogate TUs generated (all normal `.hpp` headers that are part of the Catch2 target, excluding aggregator/helper headers like `*_all.hpp`).
- Autogenerate one surrogate `.cpp` file per discovered header during the build.
- Add a build target that compiles all generated surrogate `.cpp` files and links them against the appropriate Catch2 library target so they are actually compiled during CI/testing.

Additionally, fix any Catch2 headers that fail to compile when included alone. After the change, each non-aggregate Catch2 header must compile in isolation when used as the only include in a translation unit.

Finally, ensure CI has a job/step that exercises this mode and also verifies that the set of surrogate TUs matches the set of headers (so newly added headers cannot accidentally skip the surrogate TU coverage).
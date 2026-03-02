Building GoogleTest/GoogleMock with RTTI disabled (e.g., compiling with the compiler flag `-fno-rtti`) currently fails. This is a regression introduced after a matcher-related change (bisected to a matcher-merge commit).

When RTTI is disabled, any code path that relies on C++ RTTI features (such as `typeid`, `dynamic_cast`, or APIs that implicitly require RTTI) must either be avoided or compiled out. At the moment, Google Mock’s matcher implementation still tries to use RTTI-dependent behavior in configurations where RTTI is unavailable, causing compilation to fail.

The library should compile cleanly with `-fno-rtti` while preserving existing matcher semantics. In particular, common matcher entry points like `testing::Matcher<T>`, `testing::PolymorphicMatcher`, and frequently used matchers such as `testing::Eq`, `testing::A`/`testing::An`, `testing::ContainsRegex`, and related composite matchers must remain usable in user code under `-fno-rtti`. Any internal type identification or safe downcasting performed as part of matcher wrapping/erasure needs to be compatible with RTTI-off builds.

Reproduction is simply configuring a build of googletest/googlemock with `-fno-rtti` (for example by adding it to the project’s C++ compile flags) and attempting to compile; the build should succeed without requiring RTTI.

Expected behavior: the full library (including Google Mock matchers) compiles successfully with RTTI disabled.

Actual behavior: compilation fails due to use of RTTI-dependent constructs in matcher code when built with `-fno-rtti`.
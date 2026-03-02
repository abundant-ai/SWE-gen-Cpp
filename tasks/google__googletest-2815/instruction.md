Building GoogleTest/GoogleMock with Clang in C++11 mode (especially with warnings-as-errors) currently fails or emits deprecation warnings when using parameterized matcher macros such as MATCHER_P/MATCHER_P2 and related generated matcher classes. Clang reports that the implicit copy constructor is deprecated because the type declares a copy assignment operator (often made private or deleted via GTEST_DISALLOW_ASSIGN_ / GTEST_DISALLOW_MOVE_ASSIGN_), e.g.:

  definition of implicit copy constructor for 'FooMatcherP2<double, double>' is deprecated because it has a user-declared copy assignment operator [-Werror,-Wdeprecated]

This warning can be triggered simply by defining and using a custom matcher created via the MATCHER_P-family macros in typical GoogleMock expectations; in toolchains that treat warnings as errors, it becomes a hard compile failure.

The matcher/action/internal utility types that use the GTEST_DISALLOW_{MOVE_,}ASSIGN_ macros should no longer cause -Wdeprecated warnings under Clang when compiled with -Wdeprecated enabled. In addition, these types should support normal move semantics where appropriate (move construction/assignment should not be implicitly blocked by declaring/deleting copy assignment), so moving such objects does not silently fall back to deprecated copy construction.

After the fix, projects should be able to compile GoogleTest/GoogleMock with Clang using -Wdeprecated (and optionally -Werror) without any deprecation diagnostics originating from GoogleTest/GoogleMock headers, including code that:

- Declares matchers using MATCHER_P / MATCHER_P2 / similar macros and copies/moves the resulting matcher objects.
- Uses common GoogleMock actions (including polymorphic/templated actions) that may internally store callable objects and get copied/moved during expectation setup.

One specific area that must behave correctly is VariadicMatcher: copying and moving VariadicMatcher and objects that wrap it should compile cleanly under Clang with -Wdeprecated enabled, and should preserve correct matcher semantics (no change in observable matching behavior), while also allowing moves when the underlying members are movable.

Overall expected behavior: enabling -Wdeprecated in the build should not produce any warnings from GoogleTest/GoogleMock itself, and common matcher/action usage should compile in C++11+ without triggering deprecated implicit special member generation warnings.
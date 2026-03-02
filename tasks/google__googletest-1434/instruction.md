GoogleTest should be able to build and run both with and without Abseil available, but currently parts of the codebase assume Abseil is present unconditionally, causing build failures or behavior differences when Abseil isn’t in the dependency graph.

The library needs an option to enable Abseil integration when Abseil is available, while keeping a fully functional fallback path when it is not. In particular, printing/formatting behavior used by GoogleTest’s universal value printer must remain correct in both configurations.

When Abseil is not enabled/available, including and using GoogleTest should not require any Abseil headers or symbols. Projects that do not link Abseil should still compile successfully and should be able to run printer-related tests such as printing standard containers, strings, and user-defined types without compilation errors.

When Abseil is enabled/available, GoogleTest may use Abseil facilities, but doing so must not change observable output formatting in a way that breaks existing expectations. For example, printing values that rely on stream operators, PrintTo() overloads, or internal formatting helpers should produce the same output as the non-Abseil build.

Fix the conditional compilation and integration points so that:

- A build without Abseil does not reference Abseil headers, namespaces, or types anywhere in public or compiled GoogleTest code.
- A build with Abseil enabled compiles cleanly and does not introduce differences in printed output for the same values compared to the non-Abseil build.
- Printer-related functionality (e.g., the universal value printer used by assertions) continues to handle a wide range of types and containers consistently in both modes.
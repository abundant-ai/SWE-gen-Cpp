The benchmark library’s command-line verbosity and internal diagnostics are incomplete and inconsistent.

1) The library should support a verbose mode enabled via a command-line option ("-v"). When "-v" is provided, internal debug messages should be emitted; when it is not provided, these messages should be suppressed. Currently, passing "-v" does not reliably enable debug output, and ad-hoc debug printing is scattered rather than routed through a consistent logging API.

Implement a small logging facility (a logging class plus a macro used at call sites) and wire it to the command-line flag parsing so that:
- "-v" enables verbose/debug logging.
- Without "-v", debug logging produces no output.
- Logging calls used throughout the library go through the new logging macro/class rather than direct prints.

2) The existing CHECK-style assertion macros should be reworked to provide clearer failure output and allow attaching additional context messages. At the moment, CHECK failures may not show enough information to diagnose problems (e.g., what condition failed and where), and there is no supported way to append an extra explanatory message.

Update the CHECK macro family so that a failed check reports a helpful diagnostic that includes at least the failed condition and a readable message, and also supports an additional user-supplied message (for example, via a streaming-style syntax) that is included in the failure output.

3) WallTime static initialization is fragile under concurrency. The WallTime time source (used by benchmark timing) currently relies on a static/one-time initialization approach that can behave incorrectly or unsafely when used from multiple threads early in program startup.

Change WallTime initialization so that it is performed via a function-local static variable (guaranteeing thread-safe one-time initialization in C++11 and later) rather than manual/atomic flag based initialization. After this change, calling WallTime-related APIs from multiple threads should not race, and the time source should be correctly initialized exactly once.

Overall expected behavior: running benchmarks normally should remain quiet except for standard benchmark output; adding "-v" should enable internal debug output via the new logger; CHECK failures anywhere in the library should produce clearer, more informative messages and accept extra context; and benchmark timing should remain correct and stable even with multi-threaded benchmarks that access WallTime early.
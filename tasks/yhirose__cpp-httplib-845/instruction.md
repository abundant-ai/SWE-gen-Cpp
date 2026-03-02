Building the library with C++ exceptions disabled (e.g., compiler flags like -fno-exceptions or equivalent on MSVC/clang-cl) currently fails because the code unconditionally uses exception syntax in several places. Typical compiler errors include:

```
error: cannot use 'try' with exceptions disabled
error: cannot use 'throw' with exceptions disabled
```

At the same time, when exceptions are enabled, users want an opt-in, global way to handle exceptions thrown from user-provided request handlers (route handlers) without having to add repetitive try/catch logic inside every handler.

Implement an exception-handling option on the server side that allows registering a global exception handler for exceptions thrown during routing/handler execution. When a user handler throws, the library should catch the exception (when exceptions are enabled), invoke the registered exception handler so the application can log/react, and then produce a safe HTTP response instead of terminating the process.

This must be compatible with builds where exceptions are disabled:

- When exceptions are disabled, the library must compile cleanly and must not contain any try/catch blocks, function-try-blocks, or throw statements in compiled code paths.
- Any API related to exception handling should be conditionally available or become a no-op in a way that still allows compilation under -fno-exceptions.

Expected behavior when exceptions are enabled:

- If a request handler throws an exception derived from std::exception, the server should intercept it during handler execution, call the global exception handler with information sufficient to log (at minimum the exception object/message), and respond without crashing.
- If a handler throws a non-std exception, the server should also handle it (e.g., via a catch-all), call the global exception handler, and respond without crashing.

The goal is that applications can rely on a single global exception handler for all routes, while projects that compile with exceptions disabled can still use the library without compilation errors.
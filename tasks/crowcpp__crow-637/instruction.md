Crow currently has no supported way to install a global exception handler that can turn uncaught exceptions from route handlers into a custom HTTP response. If a route throws and the exception escapes, Crow responds with HTTP 500 and an empty body, and users cannot intercept this centrally (middleware cannot do it because there is no `next` mechanism).

Add a configurable, application-level exception handler API so that users can register a callback that is invoked whenever an exception escapes from any route handler. The API should be available on the main app object (for example `SimpleApp`) as a method named `exception_handler(...)`.

The registered handler must be able to generate/modify the response. The intended usage looks like:

```cpp
SimpleApp app;

app.exception_handler([](crow::response& res) {
    try {
        throw;
    } catch (const std::exception& e) {
        res = crow::response(500, e.what());
    }
});
```

Behavior requirements:

- If `exception_handler(...)` is not called, Crow must preserve the existing behavior: when a route handler throws and the exception escapes, the framework returns HTTP status code 500 with no response body.
- If a custom exception handler is installed, and a route handler throws, Crow must catch the exception at the framework boundary and invoke the custom exception handler to populate the `crow::response`.
- The exception handler must be invoked in a context where `throw;` rethrows the original exception (so the handler can discriminate exception types and access `what()`), rather than receiving an already-decayed/translated error.
- The mechanism must apply globally to all routes handled by the app (not per-route).

After this change, applications should be able to implement a single global error/exception policy similar to Flask/Express, without needing to wrap every route body in `try/catch`.
Crow’s `crow::App<...>` currently only supports default construction. This makes middleware initialization awkward and prevents using middleware types that are not default-constructible or are move-only.

Problem:
When an application is declared with middleware types that cannot be default-constructed (or cannot be copied), users cannot construct the app while providing already-created middleware instances. The only available workflow is default-constructing the app and then assigning into `get_middleware<T>()`, which implicitly requires that all middleware be default-constructible and assignable, and it does not support initializing move-only middleware cleanly.

Required behavior:
`crow::App<Middleware...>` (and common aliases like `crow::SimpleApp` where applicable) must support constructing the app by passing a subset of middleware instances directly to the constructor, in any order. Middleware not provided should be constructed as they are today (if possible), but provided middleware objects must be moved/forwarded into the app without requiring default construction or copying.

This must work for move-only middleware, e.g. a middleware type like:
```cpp
struct D {
  D() = delete;
  D(const D&) = delete;
  // move operations may exist
};
```

Example that should compile and behave correctly:
```cpp
crow::App<A, B, C, D> app(D{args...}, A{args...});
```
Constraints/expectations:
- The constructor should accept any subset of the middleware types listed in `crow::App<A,B,C,D>`.
- The subset may be passed in any order.
- Passing a middleware instance should not require it to be copyable; move-only objects must be supported.
- Existing code that uses the default constructor and then assigns via `app.get_middleware<T>() = T{...};` should continue to work unchanged.
- The type-based middleware access API `get_middleware<T>()` should still return the correct instance after construction, whether it was provided via the new constructor or default-constructed internally.

If construction is attempted with arguments that do not correspond to any of the app’s middleware types, or if the same middleware type is provided more than once, it should fail to compile (or otherwise be rejected in a clear way consistent with the project’s template style), rather than silently selecting an unintended middleware.
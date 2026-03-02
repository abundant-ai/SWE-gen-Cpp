Crow’s CookieParser middleware currently only supports setting plain cookies as `key=value` and does not provide a way to attach standard HTTP cookie attributes (such as `Expires`, `Max-Age`, `Path`, `Domain`, `Secure`, `HttpOnly`, `SameSite`). This limitation prevents implementing higher-level features like session middleware that must be able to control cookie lifetime, scope, and security flags.

When a handler obtains the cookie context via `app.get_context<crow::CookieParser>(req)` and calls `set_cookie("key", "value")`, there should be a builder-style API that allows chaining attribute setters before the cookie is emitted in the response. For example:

```cpp
auto& cookie_ctx = app.get_context<crow::CookieParser>(req);
cookie_ctx.set_cookie("key", "value")
    .max_age(60)
    .path("/")
    .secure();
```

Expected behavior:
- Calling `set_cookie(name, value)` returns an object that supports chaining cookie attribute methods.
- Supported attributes must include all standard cookie attributes:
  - `expires(...)` (HTTP-date formatted correctly for `Set-Cookie`)
  - `max_age(int seconds)` producing `Max-Age=<seconds>`
  - `domain(string)` producing `Domain=<domain>`
  - `path(string)` producing `Path=<path>`
  - `secure()` producing the `Secure` flag
  - `httponly()` producing the `HttpOnly` flag
  - `samesite(...)` producing `SameSite=Strict|Lax|None` (and it must serialize exactly as required)
- The response must include a valid `Set-Cookie` header that combines the cookie value and the configured attributes in the correct format, e.g.:
  - `Set-Cookie: key=value; Max-Age=60; Path=/; Secure`
- Multiple cookies set through the cookie context must result in multiple `Set-Cookie` header entries (not a single comma-joined header that breaks cookie handling).

Current behavior:
- CookieParser can only set the cookie name/value, and there is no supported way to attach attributes like `Path` or `Max-Age`, so the cookie emitted in the response is missing these properties.

Implement the missing CookieParser API and serialization so that cookie attribute chaining works as shown above and generates correct `Set-Cookie` header output for all supported attributes, enabling session-style middleware to rely on it.
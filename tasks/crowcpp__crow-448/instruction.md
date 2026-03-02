Crow currently lacks a uniform way to maintain per-client session state across requests. Add a sessions middleware that can be used in an application alongside existing middlewares (notably cookie parsing) to provide a temporary key-value store associated with a client.

A new middleware type must be provided: `crow::SessionMiddleware<Store>`. It should be usable as an app middleware (e.g., `crow::App<crow::CookieParser, crow::SessionMiddleware<crow::FileStore>>`) and must allow retrieving the session object from a request via `app.get_context<Session>(req)`.

The session object must behave like a key-value map with typed access:

- Reading: `session.get<T>(key)` should return the stored value converted to `T` when present; reading a missing key should not create a session.
- Reading with fallback: `session.get(key, fallback)` should return `fallback` when the key is missing.
- Writing: `session.set(key, value)` must create a session on first write (if none exists for that client) and ensure that the session is persisted for subsequent requests from the same client.
- Primitive support: sessions must support storing values beyond strings (at least integral types and floating point), and be able to round-trip these values through the configured store.

The middleware must support at least two storage backends:

- An in-memory store (suitable for ephemeral sessions).
- A file-based store `crow::FileStore` that persists sessions to disk, supports expiration tracking, and can be constructed with a filesystem path (e.g., `crow::FileStore{"./sessions"}`) and used as `crow::SessionMiddleware<crow::FileStore>`.

Session identity and lifecycle:

- Session identity must be tied to the client through a cookie. When a session is created, the response must include the appropriate cookie so that subsequent requests from the same client load the same session.
- If there is no session cookie (or it does not correspond to a known session), the session should be treated as empty until first write.

Concurrency and synchronization requirements:

- Active sessions must be kept in a shared pool/cache such that two concurrent requests from the same client share the same underlying session object (not independent copies). This is required so that updates in one request are visible to the other without losing data.
- Provide atomic update support: `session.apply(key, fn)` must apply `fn` to the current value and store the result such that concurrent increments (e.g., `apply("views", [](int v){ return v + 1; })`) do not drop updates.
- Provide a per-session mutex: `session.mutex()` must return a mutex that is guaranteed to be the same mutex for all threads handling requests for the same client/session, allowing callers to lock around multi-key operations.

The result should allow a user to:

```cpp
using Session = crow::SessionMiddleware<crow::FileStore>;
crow::App<crow::CookieParser, Session> app{Session{crow::FileStore{"./sessions"}}};

auto& session = app.get_context<Session>(req);

auto views = session.get<int>("views");
std::string country = session.get("country", std::string{"US"});
session.set("ad_score", 10.0);

session.apply("views", [](int v){ return v + 1; });
std::lock_guard<std::mutex> lock(session.mutex());
```

Currently, these session operations are not available and session state cannot be persisted and safely shared across concurrent requests; implement the middleware and storage behavior so that session creation, cookie-based identity, typed get/set, persistence (memory and file), and concurrency semantics all work as described.
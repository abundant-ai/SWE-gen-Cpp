The HTTP client API currently signals request failure by returning `nullptr` instead of a `std::shared_ptr<httplib::Response>`, but it provides no way to determine why the request failed (e.g., connection error, timeout, SSL error, DNS failure). This makes it difficult for callers to handle failures appropriately.

Add an error reporting mechanism to the existing client API without breaking existing code that relies on the `nullptr`-on-failure behavior.

When a request fails (and the API returns `nullptr`), users must be able to query the client for the reason of the most recent failure. The mechanism should allow distinguishing common failure categories such as connection failures and timeouts. For example, after a failed call like `auto res = cli.Get("/path");` where `res == nullptr`, the caller should be able to call a client method to retrieve a structured error indicator (e.g., an enum or similar) describing what went wrong.

Expected behavior:
- Successful requests continue to return a non-null `std::shared_ptr<Response>` and should set the error indicator to a “success/no error” state.
- Failed requests continue to return `nullptr` (to preserve backward compatibility), but the client must expose the failure reason via a new API.
- The reported error must correspond to the actual failure mode (e.g., if a request times out due to configured timeouts, the error should indicate a timeout rather than a generic failure).
- The error state should be reliably updated per request so that callers can make multiple requests and observe the correct error for the most recent call.

Actual behavior:
- On failure the request returns `nullptr` and there is no supported way to retrieve the failure reason; different failure modes are indistinguishable to the caller.
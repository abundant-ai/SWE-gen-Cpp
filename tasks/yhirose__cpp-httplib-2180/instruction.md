When using `httplib::Client` over a Unix domain socket (`set_address_family(AF_UNIX)`) to talk to services like the Docker daemon, requests can fail if the request target is provided as an absolute URI (e.g. `"http://localhost/v1.39/images/json"`). Docker accepts requests like `GET http://localhost/v1.39/images/json HTTP/1.1` over the Unix socket, while `cpp-httplib` currently mishandles this style of request target.

Reproduction:
- Create a `httplib::Client` with the Unix socket path (e.g. `httplib::Client cli("/run/docker.sock");`).
- Call `cli.set_address_family(AF_UNIX);`.
- Call `cli.Get("http://localhost/v1.39/images/json")`.

Expected behavior:
- The client should successfully perform the request over the Unix socket and the server should receive a valid HTTP/1.1 request where the request target is the absolute-form URI (or otherwise be handled in a way that the server receives the correct target).
- The response should be parsed normally (e.g. for Docker: a 200 response with JSON body for `/v1.39/images/json`).

Actual behavior:
- The request is not interpreted/serialized correctly, causing the server to reject it or the request to be made with the wrong request target (e.g. treating the provided absolute URI as a normal path in a way that doesn’t match what the server expects).

Required fix:
- Update the HTTP request handling so that `Client::Get` (and the underlying request-building logic used by other HTTP methods) correctly supports being passed an absolute URI string like `"http://localhost/..."`.
- Ensure that when an absolute URI is provided, the request is formed consistently with HTTP semantics (absolute-form request-target) so servers expecting this form (notably when using proxies or certain Unix-socket HTTP endpoints) can respond correctly.
- Preserve existing behavior for origin-form paths such as `"/v1.39/images/json"`.
- The client should remain `is_valid()` for Unix-socket usage and `Get("/hi")`-style origin-form requests over Unix sockets must continue to work.

If the request cannot be performed, the error should be surfaced via the existing `Result` / `res.error()` mechanism rather than crashing or producing undefined behavior.
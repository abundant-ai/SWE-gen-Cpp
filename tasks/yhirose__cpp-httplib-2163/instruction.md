HTTP requests made through `httplib::Client` can be configured to use Unix domain sockets by calling `set_address_family(AF_UNIX)` and constructing the client with a Unix-socket address (e.g., a filesystem path). Currently, performing a simple `Client::Get()` against a server listening on a Unix domain socket can fail even though the client reports `is_valid() == true`.

Repro scenario: start an `httplib::Server` bound to a Unix domain socket path, then create a `httplib::Client` with that same address, call `cli.set_address_family(AF_UNIX)`, and perform `cli.Get(<route>)`. The request should succeed and return a response with status `StatusCode::OK_200` and the expected body content, but instead the request fails (the `Result` returned by `Get` is not successful / contains an error).

Fix Unix domain socket support so that:
- `httplib::Client` using `AF_UNIX` can successfully connect to a Unix-socket server and complete a basic HTTP GET.
- `Client::Get()` returns a successful `Result` when the server is reachable via Unix socket, and the returned `Response` contains the correct HTTP status and body.
- `Client::is_valid()` should remain consistent with actual ability to perform requests when configured for `AF_UNIX` (i.e., avoid reporting a valid client that cannot connect due to Unix-socket address handling).

The expected behavior is that a Unix-socket HTTP server and an `AF_UNIX`-configured client can communicate reliably using the same API surface as TCP (e.g., `Get`), without requiring users to fall back to platform-specific code or manual socket handling.
Crow currently only supports listening on TCP (via configuring a port). Add support for serving HTTP over a local (Unix-domain / Windows named) socket path.

Users should be able to configure the server to listen on a filesystem/local socket path instead of a TCP port by calling a new application configuration method named `local_socket_path(...)` (this was previously proposed as `unix_path()` but should be exposed as `local_socket_path`). When `local_socket_path()` is set, the server must create/bind/listen on that local socket and accept incoming connections over it, using the existing server/request handling pipeline (routing, middleware, etc.) just as with TCP.

Expected behavior:
- If the user configures `app.local_socket_path("/some/path")` and runs the app, Crow listens on that local socket path rather than on a TCP port.
- If the socket path already exists from a previous run, startup should not fail due to the leftover file; the server should handle the pre-existing socket path appropriately so it can start cleanly.
- When the server shuts down, it should clean up the local socket endpoint (remove the socket file) so subsequent runs do not fail.
- The feature should work on Unix-like platforms and also on Windows (even if the underlying implementation differs), so `local_socket_path()` should not be a Unix-only compile-time option.
- TCP behavior must remain unchanged: if the user sets a port (and does not set `local_socket_path()`), Crow should continue to listen on TCP exactly as before.

Actual behavior (current main branch):
- There is no way to configure a local socket listener; only `app.port(...)` is supported, so applications that need a local socket endpoint cannot use Crow without duplicating or heavily modifying server classes.

Implement the public API and server-side listening so that existing apps can switch between TCP and local-socket listening by choosing either `port(...)` or `local_socket_path(...)`, with correct lifecycle handling (startup, accept loop, shutdown cleanup).
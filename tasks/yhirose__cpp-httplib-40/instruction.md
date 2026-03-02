The HTTP client currently has no way to bound how long it blocks while trying to connect to an unreachable server/port. For example, creating a `httplib::Client` and calling `cli.Get(...)`/`cli.Post(...)` to a host that is down or a port with no listener can block for a long time (or appear to hang), instead of failing after a caller-defined timeout.

Add connection-timeout support to `httplib::Client` so that callers can configure how long the client will wait for the TCP connection to be established. The API should allow setting a timeout value (e.g., 5 seconds) on the client instance, and then any request (`Get`, `Post`, etc.) must return within that time if the connection cannot be established.

Expected behavior:
- A caller can configure a connection timeout on a `httplib::Client` instance (for example: 5 seconds).
- When connecting to an unreachable server or a closed port, the request call must stop waiting once the configured timeout elapses.
- On timeout or connection failure, the request should fail cleanly by returning a null response (`nullptr`) rather than blocking indefinitely.

Also ensure the client does not terminate the process with a SIGPIPE when the hostname/port is wrong or the peer is not reachable. In those failure cases, requests should fail gracefully (e.g., returning `nullptr`) without raising SIGPIPE.

A minimal example of the desired usage is:
```cpp
httplib::Client cli(serverAddress.c_str(), port);
cli.set_connection_timeout(5, 0); // 5 seconds (exact signature may vary but must allow seconds/usec style)
auto res = cli.Post(path, data, "text/plain");
if (res == nullptr) {
  // should reach here after ~5 seconds when server is unreachable
}
```
The timeout should apply specifically to the connection phase (before sending the HTTP request body), so that a down server/closed port does not cause an unbounded stall.
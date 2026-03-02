Crow’s HTTP server should be able to listen on a Unix domain socket (AF_UNIX) in addition to TCP. Right now, attempting to run the server bound to a Unix socket path either fails to start correctly or does not accept connections as expected, and it does not reliably clean up the socket file on shutdown/restart.

Implement proper Unix domain socket listening support so that:

- The server can be configured to bind/listen on a filesystem socket path (e.g. "/tmp/crow.sock") and successfully accept HTTP connections over that socket.
- If the socket path already exists from a previous run, the server should handle this gracefully: it should not fail with an “address already in use” style error just because the stale socket file exists, and it should ensure the socket file is removed/overwritten in a safe way before binding.
- On normal shutdown, the server should clean up after itself by unlinking/removing the created socket file.
- The HTTP semantics over the Unix socket should match TCP behavior (request parsing, routing, and responses should behave the same).

The change should integrate with Crow’s existing server startup API (the same style used for TCP bind/port selection) and should work in the existing threaded/asynchronous server model without breaking TCP listening. The goal is that a user can start Crow on a Unix socket path and successfully make an HTTP request through that socket, and repeated start/stop cycles do not leave an unusable stale socket behind.
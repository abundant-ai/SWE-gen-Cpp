WebSocket close handling is currently not RFC6455-compliant and can also crash the server on unclean client disconnects.

1) Missing/incorrect close status code handling
When a WebSocket peer sends a Close control frame with a payload, the first two bytes of that payload are the 2-byte closing status code (network byte order), followed by an optional UTF-8 reason string. Crow’s current close handling treats the close payload as a plain message string and exposes only a single string to user code. As a result, standards-compliant clients (e.g., browsers) interpret the first two bytes of the string as the close code, and the “reason” string observed by user code is effectively missing those bytes / is misinterpreted.

Crow should parse the Close frame payload into:
- a uint16_t close status code (from the first two bytes when present)
- a textual reason (remaining bytes after the status code)

This parsed code and reason must be provided to the application-level close callback. The WebSocket route close callback should support a handler of the form:

```cpp
.onclose([](crow::websocket::connection& conn, const std::string& reason, uint16_t code) {
    // ...
});
```

Expected behavior:
- If a Close frame includes a payload of at least 2 bytes, the callback receives `code` equal to that 16-bit status code, and `reason` equal to the remaining bytes after those two.
- If a Close frame has no payload (or fewer than 2 bytes), the callback still runs; `reason` should be empty (or whatever is actually present after parsing) and `code` should be set consistently (e.g., 0 / “no status code present”) rather than corrupting the reason.

2) Server crash on unclean disconnect / remote endpoint inspection
In unclean disconnect scenarios (e.g., client disables Wi‑Fi and later re-enables it), the server can crash while handling the disconnect. A reported crash message is:

`[Error  ]: Worker Crash: An uncaught exception occured: remote endpoint: Transport endpoint is not connected`

This appears to be triggered during close handling when code attempts to obtain remote endpoint information (e.g., via `conn.get_remote_ip()`), which can throw when the underlying transport is no longer connected. In some cases this throw is not safely contained and the worker thread crashes.

Expected behavior:
- Unclean disconnects must not crash the server.
- Close handling should be resilient when remote endpoint information is unavailable; exceptions from endpoint queries (such as `get_remote_ip()`) must not propagate out of the close path and bring down the worker.
- The close callback should still be invoked when feasible, but the server must remain stable even if endpoint queries fail.

After implementing, code that defines WebSocket routes in external functions should compile and be able to register an `.onclose` handler with the `(connection&, std::string const&, uint16_t)` signature.
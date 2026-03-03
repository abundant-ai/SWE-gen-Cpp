WebSocket (ws://) transport is currently unreliable/broken, particularly affecting PUB/SUB over WebSockets, and it also makes source history harder to trace via git blame due to unstable formatting/line mapping. The library should correctly support binding and connecting to WebSocket endpoints, including endpoints that include a path segment and endpoints without a path.

When a server socket binds to a WebSocket endpoint using a wildcard port (for example, `ws://*:*/roundtrip`), retrieving the bound endpoint via `zmq_getsockopt(..., ZMQ_LAST_ENDPOINT, ...)` should return a usable ws:// address. A client socket should be able to connect to that address (with the common adjustment of replacing `0.0.0.0` with `127.0.0.1` on platforms where connecting to `0.0.0.0` is invalid), exchange messages successfully (REQ/REP roundtrip), then cleanly disconnect and unbind without errors.

The same must work when the server binds without providing a path, e.g. `ws://127.0.0.1:*`: after binding, the returned `ZMQ_LAST_ENDPOINT` must be connectable as-is by a client, and a message roundtrip must succeed.

In addition, WebSocket connections must properly support the expected liveness behavior for idle connections: when a heartbeat mechanism is configured/used, the connection should remain stable and not be spuriously dropped while both endpoints are healthy, and it should detect real peer loss in a timely way.

Currently, one or more of these scenarios fails (bind/connect addresses are mishandled and/or PUB over WS does not function correctly), causing WebSocket-based messaging to break. Fix the WebSocket transport so that:

- Binding to `ws://...` with or without a path produces a correct `ZMQ_LAST_ENDPOINT`.
- Connecting to the returned endpoint succeeds and message roundtrips work reliably.
- Disconnect/unbind complete successfully after use.
- WebSocket heartbeat behavior works as expected (no false disconnects; real disconnects are detected).

Ensure these behaviors work consistently across platforms, including Windows where connecting to `0.0.0.0` is not valid.
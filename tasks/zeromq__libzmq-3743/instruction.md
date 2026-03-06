When using the WebSocket transports (ws:// and wss://), retrieving the last bound endpoint via the socket option `ZMQ_LAST_ENDPOINT` returns an address that is not usable for clients to connect when wildcards are used in `zmq_bind()`.

Reproduction:
- Create a REP socket and bind it to a wildcard WebSocket endpoint with a path, e.g. `zmq_bind(sock, "ws://*:*/roundtrip")` (similarly for `wss://*:*/roundtrip`).
- Call `zmq_getsockopt(sock, ZMQ_LAST_ENDPOINT, buf, &buflen)`.
- Take the returned string and attempt to connect a REQ socket to it (or to the same host/port plus the same path).

Actual behavior:
- The string returned by `ZMQ_LAST_ENDPOINT` for ws/wss binds does not represent a concrete, connectable endpoint. In particular, it may still contain wildcards (like `*` for host and/or port) and/or omit the information needed to reconstruct a usable client address. As a result, attempting `zmq_connect()` using that value fails or connects to an invalid location.

Expected behavior:
- After a successful `zmq_bind()` to a ws/wss address that includes wildcards, `ZMQ_LAST_ENDPOINT` must return a fully resolved endpoint string that a client can pass to `zmq_connect()`.
- The returned endpoint must preserve the correct transport scheme (`ws://` vs `wss://`) and must include the actual resolved port chosen by the OS when binding to `*` (ephemeral port). If the bind used a wildcard host, the returned endpoint should be usable for local connections (for example by resolving to a concrete host such as a loopback address instead of `*`).
- The returned string should be a valid ZeroMQ endpoint string (NUL-terminated when stored in a user-provided buffer) and fit within the buffer length semantics of `zmq_getsockopt`.

Concretely, the following workflow must work for both `ws` and `wss`:
```c
void *sb = zmq_socket(ctx, ZMQ_REP);
zmq_bind(sb, "ws://*:*/roundtrip");
char endpoint[...]; size_t size = sizeof(endpoint);
zmq_getsockopt(sb, ZMQ_LAST_ENDPOINT, endpoint, &size);
// endpoint should now be connectable
void *sc = zmq_socket(ctx, ZMQ_REQ);
zmq_connect(sc, endpoint); // must succeed
```
If the bind address included a resource path, the last endpoint returned should allow reconstructing a connect address for that same resource (i.e., the base address returned by `ZMQ_LAST_ENDPOINT` must be correct so appending the path yields a valid connect endpoint).

Fix the ws/wss transports so that `ZMQ_LAST_ENDPOINT` consistently reports the correct, connectable endpoint for wildcard binds, and ensure the behavior is consistent between `ws://` and `wss://`.
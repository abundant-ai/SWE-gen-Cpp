WebSocket connections currently accept arbitrarily large message payloads, which can lead to excessive memory usage because the server ends up reading the full message into RAM before it can be rejected. The library should provide rudimentary support for enforcing a maximum WebSocket payload size so that oversized messages are rejected during frame/message processing without buffering the entire payload.

Implement a configurable maximum payload limit for WebSockets (a per-connection or per-server setting is acceptable as long as it is exposed through the public API). When a client sends a WebSocket message whose payload length exceeds the configured maximum, the server must not continue accumulating the message content; instead, it should treat this as a protocol/size violation and close the WebSocket connection (ideally using an appropriate close code for “message too big” / 1009). The connection should be closed deterministically even if the oversized message arrives fragmented across multiple frames.

Expected behavior:
- When the max payload is not set (or set to 0/disabled), existing behavior remains unchanged.
- When the max payload is set to N bytes, any incoming WebSocket message with total payload size > N results in the connection being closed, and application-level message callbacks must not be invoked for that oversized message.
- The size check must account for fragmented messages: the accumulated payload size across continuation frames must be enforced against the same limit.
- The server should avoid reading/storing more data than necessary once it can determine the limit will be exceeded.

Actual behavior:
- Oversized WebSocket messages are accepted and processed, allowing unbounded payload sizes and forcing the server to buffer large messages in memory.
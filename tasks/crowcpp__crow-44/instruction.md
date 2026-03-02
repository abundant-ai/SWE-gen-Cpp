Crow’s WebSocket implementation has several protocol-handling issues and missing capabilities.

1) Mask bit handling for client-to-server frames
When a WebSocket client sends an unmasked frame (MASK bit = 0), Crow currently still applies “unmasking” logic, which causes unnecessary work (buffer allocation, read of a masking key, and an XOR loop) even though no masking is present. Crow should detect the MASK bit in the frame header and, when it is not set, skip reading/applying a masking key and treat the payload bytes as already usable.

Expected behavior: if MASK bit is 0, payload is read and delivered as-is with no masking operations performed.
Actual behavior: Crow behaves as if a mask is always present and applies mask-related operations even when MASK is 0.

2) Ping/Pong support exposed to users
Crow should allow servers to actively send WebSocket Ping frames and also allow sending Pong frames (not only as automatic responses). These capabilities should be exposed via the WebSocket connection API that end-users interact with (the same object used to send text/binary messages).

Expected behavior: the user-facing WebSocket connection object provides methods to send Ping and to send Pong, and these frames are encoded as proper control frames.
Actual behavior: server-initiated ping is not available (or not exposed), and users cannot explicitly send Ping/Pong frames.

3) Control frame payload length > 127 bytes
Crow currently mishandles Ping/Pong payload sizes larger than 127 bytes. WebSocket framing allows extended payload lengths (including 16-bit and 64-bit length encodings). Ping/Pong should support payload lengths beyond 127 bytes and frame them correctly.

Expected behavior: sending Ping/Pong with payload length > 127 bytes succeeds and produces a valid frame using extended payload length encoding.
Actual behavior: payloads above 127 bytes are rejected or encoded incorrectly.

4) WebSocket read robustness: stale header state
There is a bug where repeated reads can reuse stale internal header state if a read attempt occurs but no actual data is consumed from the socket. The internal “current header”/frame parsing state must be reset before each new read attempt so that subsequent reads parse from a clean state.

Expected behavior: each read attempt begins with a fresh header/frame-parse state; failed/empty reads do not corrupt subsequent frame parsing.
Actual behavior: internal header state can persist across reads and lead to incorrect parsing/behavior.

5) SSL WebSocket crash
Using WebSockets over SSL can crash in some situations (reported as a potential crash when using SSL websockets). The WebSocket over TLS path should be stable and should not crash during normal connect/read/write flows.

Expected behavior: SSL WebSocket connections can be established and used without crashes.
Actual behavior: certain SSL WebSocket usage patterns can trigger a crash.

After implementing the above, WebSocket behavior should be verifiable via a simple server/client interaction: the server can accept a WebSocket, receive both masked and unmasked client messages correctly, send Ping (optionally with a payload) and send Pong (optionally with a payload), and remain stable under SSL WebSocket usage.
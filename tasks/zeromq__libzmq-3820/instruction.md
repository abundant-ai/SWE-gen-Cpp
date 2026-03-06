ZeroMQ’s WebSocket transport has incorrect behavior when sending messages from a client, causing WebSocket masking to be handled in a way that can break normal request/reply roundtrips and heartbeat traffic.

When using WebSocket endpoints (e.g., binding a REP socket to a ws:// endpoint and connecting a REQ socket to the resolved ZMQ_LAST_ENDPOINT), basic message “bounce” roundtrips should succeed. This should work both when the server binds with a path component (e.g., ws://*:* /roundtrip) and when binding without an explicit path (ws://*:*). It should also work when heartbeats are enabled/used over the same WebSocket transport.

Currently, WebSocket framing/masking can be applied in a way that corrupts outgoing message bytes or otherwise mishandles the message buffer, particularly when the message is not shared and not constant (i.e., it is safe to modify its contents). The transport should instead apply the WebSocket mask in-place when the message buffer is mutable (not shared or constant). For message buffers that are shared or constant, masking must not mutate the original buffer and must preserve correct message contents for other users of the buffer.

After the fix, the following behaviors must hold:
- A REQ/REP “bounce” over ws:// succeeds (send from REQ, receive on REP, echo back, receive on REQ) without data corruption.
- Binding and connecting via ws:// works both with an explicit path segment and without one.
- Heartbeat-related traffic over ws:// does not break normal messaging and does not cause malformed frames or corrupted payloads.

The key requirement is that WebSocket masking logic must correctly distinguish mutable messages from shared/constant ones and only perform in-place masking when it is safe; otherwise it must preserve original message content while still producing correctly masked WebSocket frames on the wire.
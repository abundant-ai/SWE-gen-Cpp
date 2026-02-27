libzmq currently has no way to disconnect a single connected peer by its routing id. Applications using ZMQ_PEER or ZMQ_SERVER must tear down an entire endpoint or the whole socket to drop one connection, and there is no C API equivalent to JeroMQ’s disconnectPeer(routingId).

Implement a draft public C API:

```c
int zmq_disconnect_peer(void *socket, uint32_t routing_id);
```

Behavior requirements:

- For ZMQ_SERVER and ZMQ_PEER sockets, calling `zmq_disconnect_peer(socket, routing_id)` must disconnect exactly the connection associated with `routing_id` (and not affect other connected peers).
- After disconnecting, attempting to send a message to that same `routing_id` from the disconnecting side must fail with return value `-1` and `errno == EHOSTUNREACH`, and this must remain true until a new connection is formed.
- For socket types that do not support disconnecting by routing id, `zmq_disconnect_peer` must fail with return value `-1` and `errno == ENOTSUP`.
- The API should be callable on the socket regardless of type; the underlying socket implementation is responsible for either performing the disconnect or returning `ENOTSUP`.
- The operation must be thread-safe when used with thread-safe sockets.

To support this, add a socket-level hook so that the public call can be dispatched through `socket_base_t`:

- Introduce a virtual `xdisconnect_peer(uint32_t routing_id)` on `socket_base_t`.
- Add a public `socket_base_t::disconnect_peer(uint32_t routing_id)` that delegates to `xdisconnect_peer`.
- Implement `xdisconnect_peer` for the server/peer-capable socket implementation so it can locate the outbound connection/pipe associated with `routing_id` and terminate it such that internal bookkeeping is cleaned up and subsequent sends to that routing id behave as unreachable.

Reproduction scenario that must work:

1) Create two `ZMQ_PEER` sockets; bind one and connect the other using `zmq_connect_peer`, capturing the returned routing id.
2) Send a message from the connecting peer to the bound peer, setting the routing id on the message.
3) On the bound peer, receive the message and read the sender’s routing id using `zmq_msg_routing_id`.
4) Call `zmq_disconnect_peer` on the bound peer with the sender’s routing id.
5) Try sending a message back from the bound peer to the disconnected routing id; it must fail with `EHOSTUNREACH`.

The new API is draft-only (enabled when drafts are enabled) and should be exposed as a public symbol consistent with other draft APIs.
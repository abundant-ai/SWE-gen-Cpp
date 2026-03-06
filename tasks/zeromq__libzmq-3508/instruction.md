Socket monitoring created via `zmq_socket_monitor()` currently only works when the application uses a `ZMQ_PAIR` socket to connect to the inproc monitoring endpoint (e.g. `inproc://monitor-...`) and receive the monitor event messages. This limitation prevents using a single consumer to collect monitor events from many monitored sockets and makes it difficult to build global monitoring/logging, especially in scenarios with concurrent connects and thread-safe socket types.

When an application enables monitoring on a socket with `zmq_socket_monitor(socket, "inproc://monitor", ZMQ_EVENT_ALL)` and then tries to receive events by connecting a non-PAIR socket to that endpoint (for example `ZMQ_PULL` or `ZMQ_SUB`), the setup should be supported but currently fails because the monitoring endpoint effectively only allows `ZMQ_PAIR` semantics.

Update the monitoring mechanism so that the monitoring endpoint created by `zmq_socket_monitor()` can be consumed not only by a `ZMQ_PAIR` socket, but also by:

- `ZMQ_PULL` (allowing multiple monitored sockets to push events into a single collector thread via a single PULL socket that connects to multiple monitor endpoints), and
- `ZMQ_SUB` (allowing a single monitor publisher endpoint to broadcast events, letting subscribers filter which events they want).

The events delivered must remain compatible with the existing monitor message format produced by `zmq_socket_monitor()` (event id/value in the first frame, and endpoint string in the second frame, as currently emitted). Existing uses with `ZMQ_PAIR` must continue to work unchanged.

Expected behavior examples:

- After calling `zmq_socket_monitor(s, "inproc://monitor-s", ZMQ_EVENT_ALL)`, it should be valid to create a `ZMQ_PULL` socket and `zmq_connect(pull, "inproc://monitor-s")`, then `zmq_recv` monitor event messages successfully.
- It should also be valid to create a `ZMQ_SUB` socket, `zmq_connect(sub, "inproc://monitor-s")`, set subscription as desired (including subscribing to everything), and then receive monitor event messages.
- `zmq_socket_monitor()` must still reject non-`inproc://` monitoring endpoints with `EPROTONOSUPPORT`.

The change is considered correct when applications can reliably receive monitor events using PAIR, PULL, or SUB sockets connected to the monitor endpoint, without breaking existing monitor behavior or event formatting.
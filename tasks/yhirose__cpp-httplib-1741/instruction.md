When using httplib’s server with a ThreadPool, accepted connections are enqueued into an internal jobs queue. Under very high load, this queue can grow without bound, which leads to two user-visible problems: (1) requests experience extreme latency (clients repeatedly time out because work sits in the queue too long), and (2) memory usage can grow until the process runs out of memory.

The ThreadPool should support an optional maximum size for its pending jobs queue. When the queue has reached this limit, newly accepted jobs must not be enqueued indefinitely; instead, the server should apply backpressure by rejecting the work promptly. In practical terms, when the server accepts a socket/connection and attempts to dispatch it to the ThreadPool, if the queue is already at the configured maximum, the dispatch should fail and the connection should be closed rather than waiting for the queue to drain.

Add a way to configure this limit on ThreadPool construction/initialization (keeping existing behavior as the default: if no limit is specified, the queue remains unbounded as it is today). Ensure that when a limit is set:

- Enqueuing jobs beyond the limit is prevented.
- The server does not block indefinitely trying to enqueue; it should reject promptly.
- The server remains stable under load (no unbounded memory growth from the jobs queue).
- Existing behavior is preserved when the limit is not configured.

The change should be observable from user code by creating a server configured with a ThreadPool that has a small queue limit, then generating more concurrent connection attempts than the pool + queue can handle: excess connections should be rejected/closed quickly instead of piling up and being serviced much later.
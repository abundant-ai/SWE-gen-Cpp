cpp-httplib is missing (or has incomplete) support for two related runtime capabilities that are expected to work together in real applications: (1) first-class WebSocket support with automatic heartbeat to keep otherwise-idle connections alive, and (2) a dynamic thread pool implementation that can grow under load and shrink after being idle.

WebSocket
When using the server-side WebSocket route registration API, a server should be able to accept a WebSocket connection at a path and provide a `ws::WebSocket` object that supports a simple read/send loop.

Expected behavior:
- A server can register a WebSocket endpoint like:
  ```cpp
  Server svr;
  svr.WebSocket("/ws", [](const Request&, ws::WebSocket& ws) {
    std::string msg;
    while (ws.read(msg)) {
      ws.send(msg);
    }
  });
  ```
- A client can connect using `ws::WebSocketClient`:
  ```cpp
  ws::WebSocketClient client("ws://localhost:<port>/ws");
  bool ok = client.connect();
  ```
  `connect()` should return true on a successful handshake.
- The connection must remain open even if the application does not send any messages for longer than the configured WebSocket read timeout, as long as automatic heartbeat is enabled.
  - Heartbeat is controlled by the compile-time macro `CPPHTTPLIB_WEBSOCKET_PING_INTERVAL_SECOND` (ping interval) and the read timeout is controlled by `CPPHTTPLIB_WEBSOCKET_READ_TIMEOUT_SECOND`.
  - Scenario: with `CPPHTTPLIB_WEBSOCKET_PING_INTERVAL_SECOND` set to 1 second and `CPPHTTPLIB_WEBSOCKET_READ_TIMEOUT_SECOND` set to 3 seconds, keeping the connection idle for ~5 seconds should not cause the client to time out or close.
  - After being idle beyond the read timeout, `client.is_open()` should still be true, and the client should still be able to `send()` a message and `read()` the echoed response.
- Over multiple heartbeat cycles, the connection should remain stable: repeated waits (e.g., ~1.5 seconds) followed by send/read exchanges should continue to work while `client.is_open()` remains true.
- `ws::WebSocketClient::close()` should close the connection cleanly.

Actual behavior to fix:
- Without correct heartbeat/ping handling, idle WebSocket connections can time out and close once the read timeout elapses, causing `client.is_open()` to become false and/or `send()`/`read()` to fail after an idle period.

Dynamic thread pool
`httplib::ThreadPool` should support both fixed-size and dynamic sizing behavior depending on constructor arguments.

Expected behavior:
- Basic task execution works:
  ```cpp
  ThreadPool pool(4);
  std::atomic<int> count{0};
  for (int i = 0; i < 10; i++) pool.enqueue([&]{ count++; });
  pool.shutdown();
  // count must be 10
  ```
  `shutdown()` must block until queued work is finished and all worker threads are stopped (or otherwise guarantee tasks are completed before returning).
- Fixed-size mode: constructing `ThreadPool(base_n)` must behave like a fixed pool (no dynamic growth). Enqueuing many tasks must complete successfully after `shutdown()`.
- Dynamic scale-up: constructing `ThreadPool(base_n, max_n)` with `max_n > base_n` must allow the pool to create additional workers when the base workers are saturated and more tasks are enqueued.
  - Scenario: with `ThreadPool(2, 8)`, if two long-running tasks occupy the base threads and additional tasks are enqueued, more than 2 tasks must be able to run concurrently (i.e., observed peak parallelism must exceed the base size).
- Dynamic shrink: temporary/dynamic workers should exit after being idle for `CPPHTTPLIB_THREAD_POOL_IDLE_TIMEOUT` seconds (a compile-time macro). Base workers should remain alive.
  - Scenario: with `CPPHTTPLIB_THREAD_POOL_IDLE_TIMEOUT` set to 1 second, after a burst of work that requires scaling up, waiting long enough for all tasks to finish plus the idle timeout should allow the pool to shrink back down. After shrinking, the pool must still accept new tasks and execute them successfully.

Actual behavior to fix:
- If dynamic scaling is missing or incorrect, peak concurrency never exceeds the base thread count under load.
- If shrink is missing or incorrect, the pool may keep extra threads alive indefinitely, or it may shrink too aggressively and stop processing new work (e.g., enqueueing after an idle period fails or never runs).

Implement (or correct) the `Server::WebSocket(...)` endpoint behavior, the `ws::WebSocket` and `ws::WebSocketClient` APIs needed for connect/is_open/read/send/close, including automatic heartbeat pings that prevent idle timeouts, and implement (or correct) `ThreadPool` dynamic growth/shrink behavior as described above.
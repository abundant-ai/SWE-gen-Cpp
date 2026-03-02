There is currently no supported way to consume Server-Sent Events (SSE) streams using a dedicated, event-driven client API. Users need a C++11-compatible SSE client that can connect to an SSE endpoint, parse the SSE framing correctly, and expose events to user code, including support for event type, id, and data fields.

Implement a new class `httplib::SSEClient` that can be used to consume SSE streams over HTTP in a modern callback-based style. A user should be able to construct an `SSEClient` for a host/port (and path), start receiving events asynchronously, and stop gracefully.

Expected behavior:

- When connecting to an SSE endpoint that returns `text/event-stream`, `SSEClient` must continuously read the response body and parse SSE messages according to the SSE format:
  - Lines are UTF-8 text separated by `\n` (handle optional `\r\n`).
  - Fields include `event: <type>`, `data: <payload>`, and `id: <id>`.
  - Multiple `data:` lines in a single event must be concatenated with a newline between them.
  - A blank line terminates an event; at that point, the client should invoke the user’s event callback with the parsed event information.
  - Lines beginning with `:` are comments and must be ignored.

- The client must support auto-reconnect behavior when the connection drops unexpectedly:
  - Reconnect should happen automatically without the user needing to restart the client.
  - If an `id` was received for the last delivered event, the next connection should include the `Last-Event-ID` header with that id.

- The API must support asynchronous operation:
  - Starting the SSE stream should not block the caller thread.
  - Users must be able to stop the client (e.g., on SIGINT) and have the background processing terminate promptly and cleanly.

- The API must provide clear callbacks for:
  - Successful connection/open.
  - Receiving an event (with at least: event type/name, data, and id).
  - Error/close conditions (e.g., connection failure, parse/stream termination), so callers can react.

Actual behavior today:

- There is no `SSEClient` API in the library, so users cannot write code like `httplib::SSEClient`-based consumption with event callbacks, reconnect behavior, and graceful shutdown. The goal is to add this missing functionality as a first-class part of the library.

A minimal usage scenario that should work after the change (names may vary, but `SSEClient` must exist and provide equivalent capabilities):

```cpp
httplib::SSEClient client("localhost", 1234);

client.set_event_handler([](const httplib::SSEEvent &ev) {
  // ev.event, ev.data, ev.id
});

client.start("/events");

// ... later ...
client.stop();
```

The implementation must be C++11 compatible and integrate with the existing `httplib` client behavior (headers, connection lifecycle) so that SSE consumption is robust for long-lived streams.
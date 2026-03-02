WebSocket connections do not currently have access to the application-level handler/context (the `crow::Crow` instance, commonly called `app`). Normal HTTP connections already have a reference to this handler and can use it to access app-wide state or middleware-managed data, but WebSocket handlers cannot, which makes it difficult to build WebSocket endpoints that need shared application state.

When registering a WebSocket route and handling events like open/message/close, there should be a supported way for the WebSocket connection (or the event callbacks) to access the owning `crow::Crow`/`app` instance, similar to how regular HTTP connections can access the handler context. This should work for `crow::Crow`/`SimpleApp` users without requiring global variables or external plumbing.

In addition, streaming responses (including file downloads and response streaming) can incorrectly time out after a short period (observed as about 5 seconds), even though the connection is actively streaming data. The timeout mechanism should be canceled/disabled appropriately once streaming begins so that long-running file transfers and streamed responses do not fail due to an idle timeout while data is still being produced.

Expected behavior:
- WebSocket connections should expose a reference to the owning `crow::Crow` (the app/handler) so WebSocket callbacks can retrieve app-wide data in a clean way.
- File streaming and response streaming should not be terminated by the default timeout once streaming is underway; long downloads/streams should complete normally.

Actual behavior:
- WebSocket connections lack access to the `crow::Crow`/app handler reference.
- File downloads/streaming responses may be cut off due to a timeout firing during streaming, causing failures for transfers that take longer than a few seconds.
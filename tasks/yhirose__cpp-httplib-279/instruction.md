The HTTP server currently reads the entire request body into memory (e.g., via a `std::string`) before invoking the registered request handler. This makes it impractical to handle very large POST requests such as big file uploads, especially `multipart/form-data`, because memory usage scales with the full body size and the handler cannot process data incrementally.

Add server-side support for streaming request body consumption so that a handler can opt in to receiving the request content progressively rather than having the library eagerly read the whole body. The server routing API should allow registering a handler variant that includes an additional “content receiver” (streaming callback) which is invoked before the server starts buffering the body. When this content receiver is provided, the server must not pre-load the entire body; instead, it should pass body chunks to the receiver as they arrive, allowing the application to write them to disk or otherwise process them incrementally.

This streaming support must work for `multipart/form-data` requests as well, enabling large multipart uploads without allocating the entire payload in memory. The behavior should remain backward compatible: existing handlers that expect the full body (e.g., using `Request::body`) should continue to work as before when no content receiver is registered.

Concretely, ensure that:

- A route handler can be registered with an additional content-receiving callback (a “content receiver” / “stream handler”).
- The content receiver is called during request processing before any full-body buffering would occur.
- For large request bodies (including large multipart payloads), the server processes incoming data in chunks through the receiver rather than requiring the whole body to be stored in `Request::body` first.
- If no content receiver is supplied, the existing behavior (reading the full body into `Request::body` and then calling the handler) remains unchanged.
- Multipart parsing and/or multipart-related request handling must be compatible with this streaming mode so that multipart uploads can be handled without loading the entire multipart content into memory.

If the server cannot stream a request for some reason (e.g., protocol constraints), it should fail gracefully with an appropriate HTTP error rather than partially consuming the body and leaving the connection in an inconsistent state.
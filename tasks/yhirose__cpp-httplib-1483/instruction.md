A compilation/usage issue exists around the `httplib::DataSink` interface when streaming responses: code currently exposes and relies on `DataSink::is_writable()` as a separate pre-check to determine whether it is safe to write to the sink. This method is unnecessary and causes problems because writability is fundamentally a property of the underlying stream at the time of writing, not an independent capability that can be checked once and then assumed.

The `httplib::DataSink` API should no longer provide an `is_writable()` method. Any logic that previously depended on `DataSink::is_writable()` must be removed or rewritten so that the writability check happens inside `DataSink::write(...)` itself by consulting the underlying stream’s current state via `strm.is_writable()`.

Expected behavior:
- Projects using `cpp-httplib` should compile without any reference to `DataSink::is_writable()`.
- Streaming response code should not attempt writes when the underlying stream is not writable; instead, `DataSink::write(...)` must perform the check against `strm.is_writable()` at the moment of the write.
- If the stream is not writable, `DataSink::write(...)` should fail in the same way as other write failures in the library (i.e., signal failure to the caller consistently, rather than allowing a write attempt to proceed or requiring callers to pre-check).

Actual behavior:
- The library exposes a redundant `DataSink::is_writable()` API and uses it as an external gate, leading to incorrect or stale writability decisions and forcing downstream code to rely on an unnecessary method.

Update the `DataSink` interface and all internal call sites accordingly so that writability is handled solely within `DataSink::write(...)` using `strm.is_writable()`, and remove `DataSink::is_writable()` completely.
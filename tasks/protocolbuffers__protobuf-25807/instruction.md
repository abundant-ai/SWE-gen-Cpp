In the pure-Python Protocol Buffers runtime (when `PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python`), recursion depth accounting during binary parsing can be bypassed in certain nested-message decoding paths. This means that calling `SetRecursionLimit(...)` on a message does not reliably cap nesting depth for all message shapes, and crafted inputs can instead recurse until Python hits its own recursion limit and raises `RecursionError`, causing a denial-of-service.

The bug occurs because some internal parse/decoder paths invoke `_InternalParse(...)` on a nested message without correctly propagating the current recursion depth (or otherwise reset the depth), effectively restarting recursion accounting at 0. Since `_InternalParse` defaults `current_depth` to 0 when omitted, these call sites allow deeply nested inputs to evade the configured protobuf recursion limit.

Two specific scenarios must be handled:

1) Map fields whose values are messages

When parsing a map entry where the map value is a message type, the nested message parse must increment and propagate the recursion depth correctly. After the fix, parsing deeply nested map-message payloads must stop at the configured recursion limit (raising the protobuf parse error used for excessive recursion) rather than continuing until a Python-level `RecursionError` occurs.

2) Proto2 MessageSet parsing (`message_set_wire_format = true`) and MessageSet extensions

When parsing MessageSet items/extensions that contain nested messages, the decoder/dispatch path must also carry recursion depth through all nested `_InternalParse(...)` calls. Deeply nested MessageSet payloads must be rejected once the protobuf recursion limit is exceeded, rather than bypassing the limit and eventually raising `RecursionError`.

Expected behavior
- For the pure-Python implementation, `ParseFromString()` / `MergeFromString()` must enforce the configured recursion limit consistently across:
  - nested messages inside map values (message-valued maps)
  - MessageSet wire format parsing, including MessageSet extensions
- When the recursion limit is exceeded, parsing should fail with the protobuf recursion-depth error/exception (not `RecursionError`).

Actual behavior
- For certain nested payloads using message-valued map fields or MessageSet extensions, parsing does not respect `SetRecursionLimit(...)` and may recurse until Python raises `RecursionError`.

Implementation requirement
- Ensure that all internal decoder paths that parse embedded messages (including map-value message parsing and MessageSet parsing/extension dispatch) correctly thread and update the `current_depth` argument when calling `_InternalParse(...)`, so recursion accounting cannot be reset or dropped.

This should apply to the pure-Python runtime; other runtimes (C++/upb) are not affected by the original bypass, but MessageSet extension behavior in the Python upb surface should remain correct and consistent after the change.
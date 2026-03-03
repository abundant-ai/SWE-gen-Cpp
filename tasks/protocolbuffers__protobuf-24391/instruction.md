The upb wire decoder currently exposes and relies on a low-level EpsCopyInputStream API (`upb_EpsCopyInputStream_GetInputPtr()`) that lets callers read the raw input pointer and manually manage advancing/capture logic. This design leads to fragile call sites (for example, requiring non-obvious `IsDone()` checks) and has contributed to incorrect behavior when skipping or preserving group-encoded data.

The decoder must be updated so that `upb_EpsCopyInputStream_GetInputPtr()` is no longer part of the public API and no longer used by callers. Instead, callers must use higher-level operations with clear semantics:

- `upb_EpsCopyInputStream_ReadStringAlwaysAlias()` should advance past a region of known size and return a `upb_StringView` that aliases the input buffer for that region.
- `upb_EpsCopyInputStream_StartCapture()` / `upb_EpsCopyInputStream_EndCapture()` should support capturing a contiguous region when the final size is not known upfront (for example, while skipping a group). After ending the capture, the caller should be able to obtain a `upb_StringView` spanning the entire captured region and pointing to the original input data.

There is also a bug in `_upb_WireReader_SkipGroup()` that can cause group skipping (and unknown-group preservation/comparison) to behave incorrectly. Skipping a group should reliably consume bytes until the matching END_GROUP tag for the starting field number is reached, correctly handling nested groups. The decoder must not take the legacy code path that parses unknown groups by calling back into `_upb_Decoder_DecodeMessage()` with a NULL MiniTable; group skipping/preservation must work without attempting to decode a message with a NULL table.

After these changes:

- Code that needs to obtain an aliased view of the input for a known-length field must use `upb_EpsCopyInputStream_ReadStringAlwaysAlias()` and should not depend on raw input pointer access.
- Code that needs to preserve or reason about an unknown-length region (notably group wire types and unknown field handling) must use `upb_EpsCopyInputStream_StartCapture()` / `EndCapture()` so that the exact captured bytes can be returned as a `upb_StringView`.
- Unknown-field equality/comparison must behave correctly for groups (including nested groups) and for unknown fields with different ordering/encodings where the comparison semantics dictate equality/inequality.

A correct fix will ensure that parsing, skipping, and preserving groups is robust (including nesting), does not rely on `GetInputPtr()`, and does not attempt to decode unknown groups through `_upb_Decoder_DecodeMessage()` with a NULL MiniTable.
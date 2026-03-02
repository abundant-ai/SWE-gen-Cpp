When serializing JSON values to binary formats, float NaN and infinity values are currently encoded with the wrong floating-point width.

If a JSON value originates from a 32-bit float (e.g., created from `float`, or using a `basic_json` specialization whose number_float_t is `float`), then encoding to MessagePack and CBOR should preserve that width even for special IEEE-754 values (NaN, +Inf, -Inf). Today, these special values are incorrectly encoded as 64-bit doubles, making the output longer and using the double marker.

Reproduction example:

```cpp
nlohmann::json j_nan = std::numeric_limits<float>::quiet_NaN();
auto bytes = nlohmann::json::to_msgpack(j_nan);
```

Expected behavior for MessagePack: a float32 marker `0xCA` followed by 4 bytes of float payload. For example, NaN should start with `0xCA` and use a 4-byte NaN payload (commonly `0x7F 0xC0 0x00 0x00`), so the full encoding is 5 bytes total.

Actual behavior: the encoding starts with the float64 marker `0xCB` and uses 8 bytes of payload (13 bytes total), e.g. NaN becomes `0xCB 0x7F 0xF8 0x00 0x00 0x00 0x00 0x00 0x00`.

The same incorrect widening happens for `+infinity` and `-infinity`.

This bug should be fixed for both:
- `nlohmann::json::to_msgpack()`
- `nlohmann::json::to_cbor()`

Requirements:
- If the JSON instance’s floating type is `float` (32-bit), then NaN, +Inf, and -Inf must be encoded as float32 in MessagePack (marker `0xCA`) and as float32 in CBOR (single-precision float additional information).
- Regular finite float values (e.g., `3.14f`) must continue to encode as float32 as they already do.
- The fix must not force double encoding for float-only JSON types, and should preserve existing behavior for JSON instances whose floating type is `double`.

After the change, encoding and then decoding should round-trip consistently in terms of using float32 encoding for these special values when the source type is float (e.g., bytes produced for NaN/±Inf should match what a float32 decoder expects).
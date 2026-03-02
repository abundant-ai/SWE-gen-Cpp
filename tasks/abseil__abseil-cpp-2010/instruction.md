`absl::HexStringToBytes()` incorrectly handles some hex inputs due to sign-extension when converting decoded byte values into the output string. This shows up for byte values with the high bit set (0x80–0xFF): the produced output bytes can be wrong because intermediate values are treated as signed and then extended before being stored.

Repro: calling `absl::HexStringToBytes()` on a hex string that includes values >= 0x80 should yield a `std::string` whose underlying bytes exactly match the specified hex. For example, decoding a string containing `"80"`, `"FF"`, or mixes like `"7F80FF"` should produce a 1-byte/3-byte output with byte values `{0x80}`, `{0xFF}`, and `{0x7F, 0x80, 0xFF}` respectively.

Expected behavior: `absl::HexStringToBytes(hex)` returns the exact binary bytes represented by `hex` for all valid hex inputs, including when the resulting bytes are non-ASCII or have the high bit set. Any API overloads that return a boolean and write into an output string should likewise write the correct bytes and report success.

Actual behavior: for certain valid hex strings that decode to bytes >= 0x80, the resulting bytes in the output string are incorrect because of sign-extension during conversion.

Fix `absl::HexStringToBytes()` so that decoding is performed in an unsigned-safe way and the output string contains the correct raw byte values for the full 0x00–0xFF range.
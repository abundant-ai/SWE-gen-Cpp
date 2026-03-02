`absl::HexStringToBytes()` incorrectly decodes some valid hex strings into bytes with the wrong high-bit values due to sign extension during conversion.

When converting a hex string that contains byte values >= 0x80 (e.g., "80", "ff", or longer sequences containing such pairs), the returned `std::string` should contain the exact corresponding byte values. Instead, certain inputs yield incorrect results where decoded bytes are sign-extended (e.g., a decoded byte may not equal the intended unsigned 8-bit value), causing round-trips to fail.

Reproduction example:

```cpp
std::string out;
bool ok = absl::HexStringToBytes("ff", &out);
// Expected: ok == true, out.size() == 1, static_cast<unsigned char>(out[0]) == 0xff
// Actual (buggy): ok may still be true, but the resulting byte value is incorrect due to sign extension.
```

This also affects multi-byte inputs:

```cpp
std::string out;
absl::HexStringToBytes("7f80ff", &out);
// Expected bytes: {0x7f, 0x80, 0xff}
// Actual: bytes corresponding to 0x80 and/or 0xff are wrong.
```

`absl::HexStringToBytes()` must decode every pair of hex digits into exactly one byte in the range 0x00–0xFF, independent of whether `char` is signed or unsigned on the platform. The function should continue to reject invalid hex input as before (non-hex characters, odd-length strings, etc.), but for valid input it must produce correct byte values without sign-extension artifacts.
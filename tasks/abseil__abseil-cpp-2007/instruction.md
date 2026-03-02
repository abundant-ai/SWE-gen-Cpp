Two correctness issues need to be fixed.

1) absl::HexStringToBytes produces incorrect byte values for some inputs due to a sign-extension problem.
When converting a hex-encoded string into raw bytes, values with the high bit set (0x80–0xFF) can be decoded incorrectly on platforms where `char` is signed. For example, decoding should treat each output byte as an unsigned 8-bit value. Inputs such as "80", "ff", or longer sequences containing these bytes must produce output bytes 0x80 and 0xFF respectively (not sign-extended or otherwise altered). The function must correctly handle arbitrary binary output, including bytes above 0x7F, and round-trip behavior should be correct when converting bytes to hex and back.

Expected behavior: calling `absl::HexStringToBytes("80")` succeeds and outputs a single byte with value 0x80; calling `absl::HexStringToBytes("ff")` succeeds and outputs a single byte with value 0xFF; mixed strings like "7f80ff" decode to bytes {0x7F, 0x80, 0xFF}.
Actual behavior: some of these cases yield incorrect byte values because intermediate values are sign-extended or stored through a signed `char` in a way that changes the intended 0–255 value.

2) CRC32 implementation on MSVC incorrectly uses CRC32 intrinsics on unsupported architectures.
The CRC32 code should only use MSVC CRC32 intrinsics when building for x64 where those intrinsics are available/valid. When building with MSVC on non-x64 targets, the code should not attempt to call those intrinsics (which can lead to build failures or invalid instruction usage). The CRC32 functionality must still compile and work correctly on MSVC for non-x64 by using a portable implementation or otherwise avoiding the x64-only intrinsic path.

Expected behavior: CRC32 builds successfully on MSVC across supported targets; on x64 it may use intrinsics; on non-x64 it must not rely on x64-only intrinsics and should still produce correct CRC32 results.
Actual behavior: MSVC builds/behavior can be broken on non-x64 due to intrinsics being enabled too broadly.
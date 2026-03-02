There is a bug in `absl::HexStringToBytes()` where certain hex inputs produce incorrect output bytes due to sign extension during conversion.

When converting a hex string that includes byte values with the high bit set (i.e., values `0x80` through `0xFF`), the resulting `std::string`/byte output can contain the wrong byte values. This shows up as mismatches when comparing the produced bytes against the expected raw byte sequence for the same hex input.

Repro example:

```cpp
std::string out;
bool ok = absl::HexStringToBytes("80ff", &out);
// Expected: ok == true, out.size() == 2
// Expected bytes: {0x80, 0xFF}
// Actual (buggy): one or both bytes may be sign-extended/incorrect
```

`absl::HexStringToBytes()` should correctly interpret each pair of hex digits as an unsigned byte and append exactly that byte value to the output, preserving values in the full `0x00`–`0xFF` range. The function must not introduce sign extension or otherwise alter bytes whose most significant bit is 1.

The fix should ensure that for any valid even-length hex string (optionally with accepted formatting the API already supports), the produced output bytes exactly match the intended byte values, including for inputs that decode to bytes above `0x7F`. Invalid inputs should continue to be rejected as before (returning `false` and not producing a partially incorrect result).
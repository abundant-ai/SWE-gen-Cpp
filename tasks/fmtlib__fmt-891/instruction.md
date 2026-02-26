UTF-8 string arguments are misaligned because the library computes padding width using the number of bytes (or code units) rather than the number of Unicode code points. As a result, formatting with a minimum field width can produce no padding when it should, because a single non-ASCII character (e.g., Cyrillic) occupies multiple bytes in UTF-8 and is incorrectly treated as having a larger display width.

Reproduction example (C++):

```cpp
fmt::format(u8"{:>2}", u8"я")
```

Expected behavior: the result should be a two-character field with the string right-aligned, i.e. it should include one leading ASCII space before the single Cyrillic letter (conceptually " я").

Actual behavior: no padding is added and the result is just "я".

The same issue applies to other alignment modes (left/center) and to UTF-8 strings containing multiple non-ASCII code points: the computed width used for alignment/padding must be based on Unicode code points in the UTF-8 input rather than raw byte length. Fix the formatting logic so that when a UTF-8 string is formatted with alignment and a width (e.g., in "{:>N}", "{:<N}", "{:^N}"), the library counts the string width in Unicode code points and applies the correct padding.
When formatting floating-point values with fmt, the numeric zero-fill option ('0' in the format spec) is currently applied to non-finite values (NaN and infinity), producing incorrect output.

For example, formatting NaN with sign and zero-padded width like:

```cpp
fmt::format("{:+06}", NAN)
```

currently produces output similar to:

```
00+nan
```

This is incorrect. Per the format specification, sign-aware zero-padding is for finite numeric digits and has no effect on formatting of infinity and NaN. For non-finite values, the '0' option must be ignored, and padding should behave as if spaces were used (i.e., normal alignment/width handling without inserting zeros between the sign and the letters).

Fix the floating-point formatting logic so that for NaN and ±infinity, specifying zero-fill does not introduce any '0' characters into the formatted representation. Width and sign handling should still work, but padding must not be zero padding for these non-finite values.

The corrected behavior should apply consistently for:
- NaN with sign option and width (e.g., "{:+06}" should not yield any leading zeros)
- Positive infinity with width/sign/zero-fill combinations
- Negative infinity with width/sign/zero-fill combinations

After the fix, formatting of finite floating-point values with the '0' option should remain unchanged (still using sign-aware zero-padding for numeric digits).
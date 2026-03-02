Formatting floating-point special values incorrectly applies numeric sign-aware zero padding to infinity and NaN.

According to the formatting rules, a leading '0' in the width field enables sign-aware zero-padding for numeric types, but it must have no effect on formatting of infinity and NaN. Currently, when formatting a non-finite floating-point value (NaN/inf) with a format spec that includes sign and zero padding, the library inserts zeros before the textual representation.

For example:

```cpp
fmt::print("'{:+06}'\n", NAN);
```

Actual output is:

```
'00+nan'
```

Expected output should ignore the zero-padding behavior for non-finite values and instead use normal space padding (or no extra characters if width doesn’t require it), producing:

```
'  +nan'
```

The same rule should apply to other non-finite values such as positive/negative infinity and negative NaN when a sign is requested, across relevant float presentation types. Width must still be honored, but padding for non-finite values must not be performed with '0' sign-aware padding; i.e., formatting should behave as if the '0' flag was not specified whenever the value is NaN or infinity.
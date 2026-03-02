Formatting a `std::bitset<N>` with `fmt::format` no longer works in current versions, even though it previously worked implicitly via streaming (`operator<<(std::ostream&)`). This is a regression for users who expect `fmt::format("{}", bitset)` to produce the same textual representation as the standard stream output (a sequence of `'0'`/`'1'` characters).

When calling `fmt::format("{}", std::bitset<8>(42))`, formatting should succeed and return the bit string representation (the same as `std::ostringstream() << bitset` would produce), rather than failing to compile due to a missing formatter / unsupported type.

Implement proper support for `std::bitset<N>` by making it directly formattable via a `fmt::formatter` specialization so that:

- `fmt::format("{}", b)` works for `std::bitset<N>` and produces the standard bitset string (most significant bit first, length exactly `N`, consisting only of `'0'` and `'1'`).
- The type is treated as a normal formattable argument (i.e., it should not require opting into ostream formatting or including ostream-specific facilities to compile).
- This should work for multiple `N` values (e.g., small and larger bitsets) and not rely on implicit stream insertion.

Currently, attempting to format `std::bitset<N>` results in a compile-time error indicating that no formatter is available for the type (or an equivalent “type is unformattable” diagnostic). The expected behavior is that formatting succeeds and matches the standard textual representation of `std::bitset`.
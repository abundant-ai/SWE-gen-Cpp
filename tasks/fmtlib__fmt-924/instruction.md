Compile-time checked format strings currently only work with narrow character format literals, e.g. using the macro `FMT_STRING("...")`. When users try to use compile-time checking with wide-character format strings (or other non-`char` character types supported by the library), such as `FMT_STRING(L"...")`, compilation fails because parts of the compile-time format machinery assume `char` as the format string character type.

The library should support compile-time checked format strings for non-`char` format strings in the same way it already supports runtime formatting with both `char` and `wchar_t`. In particular, formatting APIs that accept compile-time format string wrappers should be able to accept wide string literals and perform compile-time parsing/validation, so that code like the following compiles and behaves correctly:

```cpp
auto s = fmt::format(FMT_STRING(L"{}"), 42);
// expected: s is a std::wstring equal to L"42"
```

Currently, attempting this kind of call fails to compile due to hard-coded assumptions that the compile-time format string’s `char_type` is `char`. The fix should make the compile-time format string type propagation respect the literal’s character type (e.g., `wchar_t` for `L"..."`) so that compile-time format parsing, argument checking, and formatting all work for `wchar_t` format strings.

After the change, compile-time formatting should work consistently for both narrow and wide format literals: the correct `basic_string_view<Char>`/string type should be produced, and the same format specifiers and argument checks should apply as with `char` format strings.
When configuring magic_enum to use wide-character strings by defining alias macros so that `string_view` is `std::wstring_view` and `string` is `std::wstring`, several string-based APIs do not work correctly with `wchar_t` inputs.

In this configuration, calling string-based conversion utilities like `magic_enum::enum_cast<E>(...)` with wide string literals (e.g., `L"red"`, `L"GREEN"`) should successfully parse and return the corresponding enum value when the name matches an enumerator name or a customized name provided via `magic_enum::customize::enum_name<E>(E)`. It should also support passing a comparator that operates on `wchar_t` (e.g., a case-insensitive comparator) so that `enum_cast` can match values like `L"blue"` to `Color::BLUE`.

Currently, enabling `std::wstring_view` as the `string_view` alias causes one or more of the following problems:
- `magic_enum::enum_cast` fails to compile for wide-character inputs because internal constraints/overloads assume `char`-based `std::string_view`.
- Or it compiles but fails to match names correctly (including customized wide names returned as `L"..."`), returning an empty optional where a value is expected.
- Related APIs that expose enum names (such as functions returning names as `string_view`, and streaming via the iostream integration) should also operate consistently in wide mode so that wide names can round-trip through `enum_name`/`enum_cast`.

Expected behavior:
- With `using string_view = std::wstring_view;` and `using string = std::wstring;` configured via the library’s alias macros, `magic_enum::enum_cast<Color>(L"red")` returns an engaged optional whose value is `Color::RED` when `magic_enum::customize::enum_name<Color>(Color::RED)` returns `L"red"`.
- `magic_enum::enum_cast<Color&>(L"GREEN")` returns `Color::GREEN`.
- `magic_enum::enum_cast<Color>(L"blue", comp)` returns `Color::BLUE` when `comp(wchar_t,wchar_t)` performs case-insensitive comparison.
- `magic_enum::enum_cast<Color>(L"None")` returns an empty optional.

Implement wide-character support so that the library’s string-based APIs fully respect the configured `string_view::value_type` (including `wchar_t`) instead of implicitly assuming `char`.
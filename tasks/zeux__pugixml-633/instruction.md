pugixml currently makes it awkward to use non-null-terminated string inputs (notably `std::string_view`) with name/value setters. Users who have a `std::string_view` for an attribute or node name/value must either allocate/copy into a null-terminated string or manually route through `const char* + size_t` APIs where available, and some setter call sites cannot be expressed cleanly without adding allocations.

Add initial, opt-in support for `std::string_view` for the modification APIs that already have a length-aware path. When C++17 (or later) is available and the feature is enabled, the library should expose a string-view type alias and add overloads that accept a string view directly.

Specifically, introduce a feature macro that can be enabled by users (e.g. `PUGIXML_STRING_VIEW`) and, when the standard library supports `std::string_view`, define an internal availability macro (e.g. `PUGIXML_HAS_STRING_VIEW`) and a public typedef/alias (e.g. `pugi::string_view_t`) that refers to the appropriate character type in both narrow and `PUGIXML_WCHAR_MODE` builds.

Then implement overloads for the following modification methods so they accept `string_view_t` in addition to existing overloads:
- `xml_attribute::set_name(...)`
- `xml_attribute::set_value(...)`
- `xml_node::set_name(...)`
- `xml_node::set_value(...)`
- `xml_node::set(...)` (where applicable)

These overloads must behave identically to the existing `const char* + size_t` overloads, including handling edge cases where the string-view’s `.data()` pointer may be `nullptr`.

Required behaviors:
- Calling `set_name(string_view_t())` on a valid attribute/node must succeed and set the name to the library’s default/anonymous name representation (the resulting serialized name should be `:anonymous`). Calling the same on a null/empty handle (e.g. default-constructed `xml_attribute`/`xml_node`) must return `false`.
- Calling `set_name(string_view_t(ptr, len))` must use exactly `len` characters even if the underlying buffer contains more characters.
- The same success/failure semantics must apply to `set_value(string_view_t)` and other added string-view setters: valid objects return `true` and update the DOM; null handles return `false` and do not modify anything.
- In wide-character mode, the string-view overloads must accept wide-character views and produce correct results.

Example scenario that must work when the feature is enabled on C++17+:
```cpp
pugi::xml_document doc;
doc.load_string("<node attr='value' />");

pugi::xml_attribute a = doc.child(STR("node")).attribute(STR("attr"));

// empty view should be accepted and produce :anonymous
pugi::string_view_t sv_empty;
a.set_name(sv_empty); // returns true

// length-limited rename
pugi::string_view_t sv(STR("n1234"), 1);
a.set_name(sv); // returns true, name becomes "n"
```

When the feature macro is not enabled or the standard library does not provide `std::string_view`, these overloads and related aliases/macros should not be available.
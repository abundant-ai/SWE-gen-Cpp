pugixml’s public DOM API has incomplete `std::string_view` support for name-based lookups and modifications. Some methods accept `const char*` (and sometimes `const char*, size_t`), but do not provide the corresponding `string_view_t` overloads. This forces users with non-null-terminated strings (including embedded NULs) to allocate/copy just to call core APIs like `xml_node::child()` and `xml_node::attribute()`, and makes it difficult to expose pugixml through bindings where strings are length-based.

Add the missing `string_view_t` overloads for core public APIs so that callers can pass `string_view_t` without allocations while preserving correct lookup semantics.

The lookup overloads must be correct when the `string_view_t` contains embedded NUL characters. In particular, a `string_view_t` such as `string_view_t("n\0pe", 4)` must NOT be considered equal to a node/attribute name `"n"` during lookups. Any implementation that uses `strncmp`/`wcsncmp`-style comparisons (which stop at the first NUL) will incorrectly treat these as equal. Additionally, range-based equality helpers that assume both inputs are safe to read past their first NUL can cause out-of-bounds reads when comparing a length-based view against a shorter null-terminated string.

Implement `string_view_t` overloads for at least the following methods so they behave consistently with the existing `const char*` overloads, but using length-aware comparisons:
- `xml_node xml_node::child(string_view_t name) const;`
- `xml_attribute xml_node::attribute(string_view_t name) const;`
- `xml_node xml_node::next_sibling(string_view_t name) const;`
- `xml_node xml_node::previous_sibling(string_view_t name) const;`
- `xml_attribute xml_node::attribute(string_view_t name, xml_attribute& hint) const;`

Also provide `string_view_t` overloads for creation/insertion and assignment operations so callers can pass `string_view_t` directly:
- `xml_attribute& xml_attribute::operator=(string_view_t rhs);`
- `xml_attribute xml_node::append_attribute(string_view_t name);`
- `xml_attribute xml_node::prepend_attribute(string_view_t name);`
- `xml_attribute xml_node::insert_attribute_after(string_view_t name, const xml_attribute& attr);`
- `xml_attribute xml_node::insert_attribute_before(string_view_t name, const xml_attribute& attr);`
- `xml_node xml_node::append_child(string_view_t name);`
- `xml_node xml_node::prepend_child(string_view_t name);`
- `xml_node xml_node::insert_child_after(string_view_t name, const xml_node& node);`
- `xml_node xml_node::insert_child_before(string_view_t name, const xml_node& node);`

Behavior requirements:
- `child(string_view_t)` and `attribute(string_view_t)` must find nodes/attributes whose names match the view exactly by length and content (including any embedded NULs).
- Name lookup must NOT match a prefix ending at a NUL. Example: searching for `string_view_t("n\0pe", 4)` must not match an element/attribute named `"n"`.
- Nodes/attributes with a null name (i.e., no name set) must not be found via lookup, even when searching with an empty name such as `string_view_t()` or an empty string.
- The overloads should be enabled/available only when `PUGIXML_HAS_STRING_VIEW` is defined, consistent with existing conditional support.

If these overloads are missing or implemented using NUL-terminated comparisons, users will observe incorrect lookups (false positives) and potential invalid memory reads when comparing length-based views against null-terminated strings.
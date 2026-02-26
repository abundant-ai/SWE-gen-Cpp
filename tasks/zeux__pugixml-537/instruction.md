Some DOM-modification APIs only accept null-terminated strings, which makes it awkward or inefficient to work with string_view-like inputs (a pointer plus an explicit length). Add size_t-length overloads for key name-based operations so callers can pass non-null-terminated names or substrings without first allocating/copying.

Implement the following overloads (keeping existing behavior for the current const char_t* overloads unchanged):

- bool xml_attribute::set_name(const char_t* rhs, size_t sz)
- xml_attribute xml_node::append_attribute(const char_t* name, size_t sz)
- xml_node xml_node::append_child(const char_t* name, size_t sz)
- xml_attribute xml_node::attribute(const char_t* name, size_t sz) const
- xml_node xml_node::child(const char_t* name, size_t sz) const
- bool xml_node::set_name(const char_t* rhs, size_t sz)

Expected behavior:
- The size-based overloads must interpret the name as the first sz characters of the buffer (it may not be null-terminated).
- They must behave exactly like the existing name-based APIs in terms of DOM effects, except the name comes from (ptr, size).
- For valid nodes/attributes, renaming via set_name(ptr, sz) must update the serialized document accordingly; e.g., renaming an attribute originally named "attr" to the first character of "n1234" using sz=1 results in the attribute name "n".
- For default-constructed/empty handles (e.g., xml_attribute() with no underlying attribute, similarly for xml_node() if applicable), set_name(ptr, sz) must fail and return false, without modifying anything.
- attribute(name, sz) and child(name, sz) must locate the attribute/child whose name exactly matches the provided length-limited string (exact length match, not prefix match).
- append_attribute(name, sz) and append_child(name, sz) must create the new attribute/child with the exact name specified by the (ptr, sz) pair.

Category of change: this is an API enhancement; the main risk is incorrect handling of non-null-terminated inputs or incorrect matching semantics (prefix/length bugs), so ensure exact-length name comparisons and correct storage of the truncated name.
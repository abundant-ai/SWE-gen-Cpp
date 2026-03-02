`crow::json::wvalue` cannot be explicitly constructed or assigned as a JSON object from common C++ object-like sources (initializer lists and associative containers). As a result, users must either default-construct a `crow::json::wvalue` and then populate fields one-by-one, or create an empty object via parsing (e.g., `crow::json::load("{}")`), which is verbose and semantically awkward.

Implement explicit object construction and assignment support for `crow::json::wvalue` so that it can be created and replaced from:

1) An initializer-list of key/value pairs, enabling syntax like:

```cpp
crow::json::wvalue v = {
  {"username", username},
  {"email", email},
  {"firstname", firstname},
  {"lastname", lastname},
};

v = {
  {"username", username},
  {"email", email},
};
```

This requires adding:
- `crow::json::wvalue::wvalue(std::initializer_list<std::pair<std::string const, crow::json::wvalue>>)`
- `crow::json::wvalue::operator=(std::initializer_list<std::pair<std::string const, crow::json::wvalue>>)`

2) Copy- and move-construction and copy- and move-assignment from `std::map<std::string, crow::json::wvalue>` and `std::unordered_map<std::string, crow::json::wvalue>`, supporting both `const&` and `&&` overloads:

```cpp
std::unordered_map<std::string, crow::json::wvalue> m = {
  {"username", username},
  {"email", email},
};

crow::json::wvalue v1 = m;
crow::json::wvalue v2 = std::move(m);

v1 = m;
v2 = std::move(m);
```

This requires adding:
- `crow::json::wvalue::wvalue(std::map<std::string, crow::json::wvalue> const&)`
- `crow::json::wvalue::wvalue(std::map<std::string, crow::json::wvalue>&&)`
- `crow::json::wvalue::wvalue(std::unordered_map<std::string, crow::json::wvalue> const&)`
- `crow::json::wvalue::wvalue(std::unordered_map<std::string, crow::json::wvalue>&&)`
- `crow::json::wvalue::operator=(std::map<std::string, crow::json::wvalue> const&)`
- `crow::json::wvalue::operator=(std::map<std::string, crow::json::wvalue>&&)`
- `crow::json::wvalue::operator=(std::unordered_map<std::string, crow::json::wvalue> const&)`
- `crow::json::wvalue::operator=(std::unordered_map<std::string, crow::json::wvalue>&&)`

After the change, `crow::json::wvalue` should treat these inputs as JSON objects (not arrays/strings), preserve the provided key/value mappings, and allow creating an empty object via an empty map/unordered_map or an empty initializer list. The new overloads must compile cleanly with typical brace-initialization usage and allow round-trip access via `operator[]` (e.g., `v["username"]`) without requiring parsing from a string.
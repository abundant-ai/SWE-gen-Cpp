Several quality-of-life APIs are missing from Crow’s query string and JSON types, preventing common REST-style usage patterns.

1) Query string API gaps
When working with a parsed query string, there is no way to (a) list all available keys or (b) consume a parameter exactly once.

Implement the following additions on the query string type:
- `keys()` must return a collection of all parameter names present in the query string.
- `pop(name)` must behave like `get(name)` in terms of retrieving the parameter’s value, but it must also remove that parameter from the query string so subsequent lookups no longer see it.

Expected behavior:
- If a key exists, `pop("a")` returns the same value as `get("a")` would have returned before removal, and then `get("a")` should behave as if the key is absent.
- If a key does not exist, `pop("missing")` should behave consistently with how missing keys are handled by `get()` (same “not found” semantics / return type behavior).
- `keys()` should reflect the current state: after `pop()`, the removed key should no longer appear.

2) json::rvalue usability additions
Crow’s `json::rvalue` currently lacks convenient ways to:
- Convert a non-container JSON value to `std::string` using an explicit conversion.
- Enumerate the contents of a JSON container (object/array) in a uniform way.
- Retrieve the keys of a JSON object.

Implement the following on `json::rvalue`:
- An `operator std::string()` conversion that allows `std::string(json["abc"])`. This conversion must return a string representation for any JSON value that is not a container (i.e., not an object and not a list/array). It should not attempt to stringify containers via this operator.
- `lo()` that returns a `std::vector<json::rvalue>` containing the elements of a JSON container. For objects, the vector should contain the values (not the keys); for lists/arrays, it should contain the elements.
- `keys()` that returns `std::vector<std::string>` with the keys of a JSON object. For non-objects, it should behave consistently (e.g., return an empty vector if there are no keys).

Expected behavior:
- `keys()` on an object returns all object member names.
- `lo()` on an object returns a vector whose length matches the number of members, containing each member’s value.
- `lo()` on a list returns a vector whose length matches the list length, containing each element.

3) json::wvalue enhancements and container behavior
`json::wvalue` needs additional constructors and container-like operations to support ergonomic building of JSON responses.

Implement the following on `json::wvalue`:
- Support object storage using either `std::map` or `std::unordered_map` (the type must be selectable/usable such that `json::wvalue` is not locked to only `std::unordered_map`).
- A copy constructor that correctly duplicates the contained JSON value.
- `size()` that returns:
  - the size of the JSON list when the value is a list/array
  - otherwise, `1` for non-list values
- A constructor that creates a `json::wvalue` from a `std::vector` (so a vector of JSON-like items can directly become a JSON list).

Expected behavior:
- Copying a `json::wvalue` produces an independent value with the same contents.
- `size()` on a list reflects the number of elements; `size()` on a scalar is `1`.
- Constructing from `std::vector` produces a JSON list with corresponding elements.

The goal is that applications can easily parse and consume query parameters (including one-time consumption via `pop()`), and can both read (`json::rvalue`) and construct (`json::wvalue`) JSON with the added conversion/enumeration utilities and the expected container semantics.
Crow’s JSON support currently behaves as if JSON values are primarily “object-like” (map/dictionary). There is no first-class JSON list/array type that can be created and manipulated in the same style as JSON objects, which prevents users from building payloads like `[1, 2, 3]` or mixing nested arrays/objects naturally.

Implement first-class JSON list support in the `crow::json` API, in a way that mirrors existing JSON object support.

The JSON API must allow:

- Constructing a JSON list value (array) and appending elements to it (numbers, strings, booleans, null, objects, and nested lists).
- Accessing list elements by index and iterating as appropriate for a list.
- Serializing (“dumping”) JSON lists correctly into valid JSON with `[]` and comma-separated elements.

At the same time, JSON objects should continue to work, but the public naming should use `object` (not `object_type`) as the canonical object container type.

Additionally, JSON number dumping must preserve floating point intent: when a JSON value is a floating point number that is mathematically an integer (e.g. `6.0`), dumping must emit `6.0` rather than `6`. In other words, dumping must distinguish integers from floating point values even when their printed value could look the same.

Examples of expected serialization:

- A list of ints: `[1,2,3]`
- A nested structure: `{"items":[{"x":1}, {"x":2}], "ok":true}`
- A floating value that is integral: `6.0` must dump as `6.0` (not `6`).

These changes must integrate cleanly with existing `crow::json::wvalue` usage patterns so that users can build objects and lists interchangeably (e.g. assigning a list into an object field, and putting an object into a list).

Finally, ensure any existing JSON object type aliases/usages exposed to users are updated so `crow::json::object` is available and usable as the standard object container type, without breaking the ability to construct/dump JSON values.
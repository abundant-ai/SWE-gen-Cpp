Catch2 should support emitting test results in JSON via a new reporter, and the current codebase is missing the required JSON reporter implementation and the underlying JSON writing behavior.

When a user selects the JSON reporter (e.g., via the normal reporter selection mechanism by name), Catch2 should produce valid, well-formed JSON output describing the test run. The reporter must be registered with the reporter registry/factory system so it can be discovered/listed and instantiated like other reporters. Reporter listing should include the new JSON reporter name and description.

In addition, a JSON writing utility is expected to exist and produce stable, pretty-printed JSON with correct escaping and indentation. A key type involved is `Catch::JsonValueWriter`, which writes JSON to a provided `std::ostream`.

`Catch::JsonValueWriter` should have these behaviors:
- Constructing `Catch::JsonValueWriter writer{stream};` must not write anything to the stream.
- `Catch::JsonValueWriter{stream}.writeObject()` must write an empty object exactly as:
  ```
  {
  }
  ```
- Writing primitive members into an object should serialize correctly:
  - integers as `1`
  - floating point as `1.5`
  - booleans as `true`/`false`
  - strings quoted and escaped as JSON strings
  - arrays and nested objects with correct commas and indentation
  For example, writing keys like "int", "double", "true", "false", "string", and "array" with appropriate values should result in output containing substrings such as:
  - `"int": 1,`
  - `"double": 1.5,`
  - `"true": true,`
  - `"false": false,`
  - `"string": "this is a string",`
  and an array formatted like:
  ```
  "array": [
      1,
      2
    ]
  }
  ```
- Nested objects must be supported, including empty objects and objects containing keys/values, with indentation increasing for nested scopes. Output should contain patterns like:
  - `"empty_object": {
    },`
  - `"fully_object": {
      "key": 1
    }`
- `Catch::JsonValueWriter{stream}.writeArray()` must write an empty array exactly as:
  ```
  [
  ]
  ```
  and `writeArray()` should allow writing multiple values with proper commas/newlines/indentation.
- The JSON writer must be able to serialize values provided via stream insertion (e.g., a custom type that has `operator<<`), producing a JSON string value from the textual representation (e.g., a `Custom` type streaming as `custom` should become a JSON string `"custom"`).

Finally, the JSON reporter should integrate with Catch2’s reporting lifecycle so that running a test session with mixed passing/failing tests results in consistent JSON output (including overall run info and per-test-case results), and the output should match the established baseline formatting for the platform configurations where baselines are used.

If the JSON reporter is selected today, it either cannot be found/constructed or produces output that is not valid JSON / not in the expected format. Implement the missing JSON reporter and JSON writer behavior so that selecting the JSON reporter works end-to-end and the produced output is correctly formatted and complete.
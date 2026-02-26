Catch2 currently lacks a built-in JSON output format for test runs. Add a first-party JSON reporter that can be selected like other reporters and produces well-formed, properly formatted JSON describing the test run and its results.

The implementation must include a JSON writing utility that can reliably emit JSON values with correct escaping, commas, nesting, and indentation. The primary API expected by other components is a streaming writer named `Catch::JsonValueWriter` that writes to a provided `std::ostream`. Its behavior should support:

- A newly constructed `Catch::JsonValueWriter` performing no output until a value is started.
- `writeObject()` emitting an empty JSON object with newlines, i.e. exactly:
  ```
  {
  }
  ```
  and returning a scoped writer that allows adding key/value pairs.
- `writeArray()` emitting an empty JSON array with newlines, i.e. exactly:
  ```
  [
  ]
  ```
  and returning a scoped writer that allows adding array elements.
- Writing object members via `writer.write("key").write(value)` for primitive types (integers, floating point, booleans, and strings) and for nested arrays/objects via `writer.write("key").writeArray()` / `writer.write("key").writeObject()`.
- Writing array elements via `writer.writeArray().write(value)` and supporting chaining multiple writes.
- Proper indentation of nested structures and placement of commas between elements/members (no trailing commas).
- Correct JSON escaping for strings.
- Ability to serialize arbitrary types that have an `operator<<` overload to `std::ostream` by converting them into JSON strings (e.g., a custom type streamed as `"custom"`).

On top of the JSON writer, implement and register a new JSON reporter so that it is discoverable through the reporter registry and selectable by name in the same way as existing reporters. The reporter must integrate with the existing reporter interfaces (factory/registry, reporter config, and streaming output) and produce deterministic JSON output suitable for baselining.

Expected behavior for selecting/listing reporters must remain correct: listing reporters should include the JSON reporter in the available reporter descriptions, and creating the reporter through the registry/factory mechanisms should succeed.

Overall, running Catch2 with the JSON reporter should produce valid JSON that captures test case execution results (pass/fail, names, and relevant metadata) and does not break existing reporter infrastructure or listing utilities.
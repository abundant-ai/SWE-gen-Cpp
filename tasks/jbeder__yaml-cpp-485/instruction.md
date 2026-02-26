yaml-cpp’s Emitter currently emits YAML null scalars only as `~`. This is valid YAML, but it is not JSON-compatible output (JSON requires the literal `null`). Additionally, when emitting double-quoted strings intended to be JSON-compatible, the Emitter can produce escape sequences that are not valid in JSON (notably `\x..` style escapes), and it may use non-JSON escaping forms such as `\U........` instead of JSON’s required UTF-16 surrogate-pair `\u....\u....` form for code points above U+FFFF.

Add Emitter manipulators that allow callers to request JSON-style output for nulls and strings:

When JSON-style null emission is enabled, emitting a null `Node` (e.g., a node created by parsing/constructing a null scalar) must output `null` instead of `~`.

When JSON-style string emission is enabled, any emitted string must be escaped in a way that is valid for JSON strings:
- Do not emit `\x` escapes.
- Use JSON-compatible `\u` escaping, including UTF-16 surrogate pair escapes for code points above U+FFFF (instead of `\U` escapes).
- Escape only the code points that YAML/JSON require to be escaped for a valid JSON string, and prefer the short two-character escape sequences where defined (e.g., `\n`, `\t`, `\\`, `\"`, etc.) rather than always using `\u` forms.

The new behavior must be controllable via emitter manipulators so existing code continues to get the current YAML-style output by default.

Example expected behavior:
- By default, emitting a null node yields `~` (current behavior).
- With the JSON null manipulator enabled, emitting the same null node yields `null`.
- With the JSON string manipulator enabled, emitting strings containing characters that require escaping produces JSON-valid escapes and never includes `\x` escapes; characters above U+FFFF are represented using surrogate pairs.

Ensure the emitter still reports success via `good()` and does not set an error for these cases, and the emitted output should remain parseable as YAML when appropriate while also being JSON-compatible when the JSON manipulators are enabled.
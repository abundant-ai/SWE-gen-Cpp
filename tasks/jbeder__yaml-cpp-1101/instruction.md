When emitting YAML with auto-quoting enabled, mapping keys that contain an ampersand (`&`) are not being quoted, which can produce invalid or misleading YAML because `&` is interpreted as the beginning of an anchor. As a result, a plain key like `a&b` may be emitted without quotes, even though it should be quoted/escaped to ensure the output is parsed as a single scalar key rather than YAML syntax.

Reproduction scenario: create a mapping where the key string contains `&` (for example, a key equal to `"a&b"`) and emit it using `YAML::Emitter` with the emitter configured to auto-quote scalars/keys when needed. The emitted YAML should quote that key (e.g., `"a&b": value` or `'a&b': value`, depending on the chosen quoting style) so that parsing the emitted YAML round-trips back to the same key string.

Current behavior: the emitter outputs the key in plain style (unquoted) even though it contains `&`.

Expected behavior: the emitter must treat `&` in keys as requiring quoting when auto-quoting is enabled, so that emitted YAML is unambiguous and parses back correctly. This should apply specifically when the scalar is being emitted as a map key (not just as a value), and should not incorrectly trigger anchor/alias emission for the key text.

Fix the emitter’s scalar/key quoting decision so that keys containing `&` are quoted/escaped appropriately under auto-quoting, ensuring the output can be parsed back into the same structure without interpreting `&` as YAML anchor syntax.
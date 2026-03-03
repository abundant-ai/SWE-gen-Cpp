When using the YAML emitter with auto-quoting enabled, mapping keys that contain an ampersand ('&') are emitted without quotes, which makes the output ambiguous/invalid because '&' introduces an anchor in YAML. As a result, a key like "a&b" can be emitted as `a&b: value` instead of being quoted, and YAML parsers may interpret the `&b` portion as an anchor rather than part of the key.

The emitter should treat an ampersand in a plain (unquoted) key as requiring escaping/quoting when auto-quoting is enabled, so that the emitted YAML round-trips correctly through parsing.

Reproduction example:
```cpp
YAML::Emitter out;
out << YAML::BeginMap;
out << YAML::Key << "a&b";
out << YAML::Value << "v";
out << YAML::EndMap;

// With auto-quoting enabled, the output should quote the key so it is not
// interpreted as an anchor.
```

Expected behavior: the emitted YAML quotes (or otherwise escapes) the key so the ampersand is preserved literally (e.g. `"a&b": v`), and the output is parseable and represents a map with a single key exactly equal to `a&b`.

Actual behavior: the emitter outputs the key without quotes (e.g. `a&b: v`), which causes incorrect YAML semantics (the `&` is treated as anchor syntax) and breaks round-trip parsing/meaning.

Fix the emitter’s scalar/key handling so that when emitting mapping keys in plain style under auto-quoting rules, the presence of `&` triggers quoting/escaping in the same way other YAML-reserved indicator characters do.
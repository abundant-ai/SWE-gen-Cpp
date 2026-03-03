When emitting YAML, YAML::Null is currently always rendered as "~". This makes it impossible to produce YAML where null values are emitted as the bare key with no value (e.g., emitting "- bar:" instead of "- bar: ~"), and it also prevents users from choosing alternative textual null spellings such as "null", "NULL", or "Null".

The emitter should support configurable styles for how YAML::Null is emitted. Add four distinct null emitter styles:

- LowerNull: emits "null"
- UpperNull: emits "NULL"
- CamelNull: emits "Null"
- TildeNull: emits "~" (the current/default behavior)

The configuration must be exposed through the Emitter API in the same spirit as existing formatting controls (e.g., string format, integer base, precision), so that users can set the null output style on an Emitter instance and have it affect subsequent emission of YAML::Null (including when emitting Nodes that resolve to null).

Reproduction example:

```cpp
YAML::Emitter out;
out << YAML::Null;
```

Expected behavior:
- By default, emitting YAML::Null should produce "~".
- After setting the null style to LowerNull, emitting YAML::Null (or a null Node) should produce "null".
- After setting the null style to UpperNull, it should produce "NULL".
- After setting the null style to CamelNull, it should produce "Null".
- After setting the null style to TildeNull, it should produce "~".

This should work consistently whether the null is emitted directly via `out << YAML::Null` or indirectly by emitting a `YAML::Node` loaded or constructed as null (e.g., a node produced by `YAML::Load("null")`). The emitter output must remain valid YAML for each style and must not cause the emitter to enter an error state (i.e., `out.good()` should remain true and `out.GetLastError()` should remain empty in these cases).
Emitting YAML null values currently always uses the tilde form (`~`). This makes it impossible to generate YAML where null is represented as `null`, `NULL`, or `Null`, which some downstream systems require. For example, when emitting a map entry with no value, users may need output like:

```yaml
- foo: 123
- bar:
- baz: "yeah"
```

but the emitter always produces `- bar: ~`.

Add support for selecting how `YAML::Null` is rendered by the emitter. The emitter must provide four distinct null emission styles:

```cpp
LowerNull   // emits: null
UpperNull   // emits: NULL
CamelNull   // emits: Null
TildeNull   // emits: ~
```

When a `Node` containing a null scalar is emitted (e.g., `Node n(Load("null")); emitter << n;`), the output must reflect the currently selected null style. The default behavior should remain `~` to preserve backward compatibility.

The selection must be expressible through the public emitter formatting/settings mechanism (similar to how string format, integer base, and precision are set). After setting the null style on an `Emitter`, subsequent emissions of `YAML::Null` (or nodes parsed as null) must use the chosen representation, without affecting emission of non-null scalars, sequences, maps, or aliases.

Expected examples for a single emitted null scalar depending on the chosen style:

- default: `~`
- with `LowerNull`: `null`
- with `UpperNull`: `NULL`
- with `CamelNull`: `Null`
- with `TildeNull`: `~`

Ensure that emitted output remains valid YAML and that changing the null style does not break parsing/round-tripping of documents that include null values.
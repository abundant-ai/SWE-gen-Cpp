When using yaml-cpp’s Emitter to emit a flow-style empty map or sequence that contains a formatting event like YAML::Newline (and similarly when combined with comment, tag, or anchor metadata), the emitter produces incorrect output by inserting an extra empty container token inside the container.

For example, emitting a map with a key "foo" whose value is a flow map that begins, contains a newline, and then immediately ends:

```cpp
YAML::Emitter out;
out << YAML::BeginMap;
out << YAML::Key << "foo";
out << YAML::Value
    << YAML::Flow << YAML::BeginMap << YAML::Newline << YAML::EndMap;
out << YAML::EndMap;
```

Expected output:

```text
foo: {
  }
```

Actual output currently produced:

```text
foo: {
  {}
```

In other words, the flow map is empty but the emitter incorrectly prints an inner `{}` after the newline. The emitter should correctly recognize that the container is empty even if a newline (or related non-content directives like comments/tags/anchors) appears between `BeginMap`/`BeginSeq` and `EndMap`/`EndSeq`, and it must not emit a phantom empty map/sequence element. This should work consistently for both flow maps (`{ ... }`) and flow sequences (`[ ... ]`) under the same conditions, while keeping the output valid YAML and ensuring the emitter reports `good()` with no error.
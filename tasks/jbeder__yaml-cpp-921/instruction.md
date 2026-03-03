When using yaml-cpp’s Emitter to emit a flow-style empty map (or sequence) that includes explicit formatting events like YAML::Newline (and similarly comment/tag/anchor), the emitter produces incorrect output by inserting an inline empty container token (`{}` or `[]`) on a new indented line instead of emitting a properly formatted empty container that respects the newline.

Reproduction:

```c++
YAML::Emitter out;
out << YAML::BeginMap;
out << YAML::Key << "foo";
out << YAML::Value
    << YAML::Flow
    << YAML::BeginMap
    << YAML::Newline
    << YAML::EndMap;
out << YAML::EndMap;
```

Expected emitted YAML:

```
foo: {
  }
```

Actual emitted YAML currently:

```
foo: {
  {}
```

The emitter should treat an empty flow map/sequence as having “empty content”, and when a newline (or other non-content events such as comment/tag/anchor) is present between BeginMap/BeginSeq and EndMap/EndSeq, it must still emit the correct empty container formatting rather than printing `{}` / `[]` as content on its own line.

Fix the emitter so that:
- A flow-style empty map with an explicit YAML::Newline between begin/end emits as an empty flow map with the newline respected (opening brace, newline, proper indentation, closing brace), not as a brace + newline + `{}`.
- The same principle applies to empty flow sequences (`[]`) and to cases where the only “content” between begin/end is a comment, tag, or anchor: these should not cause the emitter to output an inline empty container token as if it were a node value.
- The produced output must keep the emitter in a good state (no emitted errors), and the emitted YAML should be parseable.

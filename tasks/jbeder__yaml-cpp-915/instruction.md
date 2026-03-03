When emitting a parsed YAML::Node, global formatting options set on YAML::Emitter (such as sequence and map format) should take precedence over any style preserved on the Node from parsing. A regression causes the emitter to ignore YAML::Emitter’s global style settings and instead emit in the original block style stored on the node.

Reproduction:

```cpp
YAML::Node node = YAML::Load(
  "foo:\n"
  "  - 1\n"
  "  - 2\n"
  "  - 3\n"
  "bar: baz\n");

YAML::Emitter out;
out.SetSeqFormat(YAML::Flow);
out.SetMapFormat(YAML::Flow);

out << node;
std::string actual = out.c_str();
```

Expected output (flow styles applied globally):

```
{foo: [1, 2, 3], bar: baz}
```

Actual output (node’s preserved block styles override emitter settings):

```
foo:
  - 1
  - 2
  - 3
bar: baz
```

The bug occurs during event-based emission when starting containers: style information associated with the node is being applied in a way that overrides YAML::Emitter’s global defaults. In particular, emission of sequences/maps started from node-driven events should respect the current emitter configuration set via YAML::Emitter::SetSeqFormat() and YAML::Emitter::SetMapFormat() unless the user explicitly changes style for that specific emission scope.

Fix the emission logic so that when a YAML::Node is streamed into a YAML::Emitter, the emitter’s global style settings are not overridden by the node’s stored style, and the above reproduction emits the expected flow-formatted YAML.
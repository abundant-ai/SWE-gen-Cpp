When emitting YAML from a parsed Node, global formatting settings applied to an Emitter (such as sequence and map format) are being incorrectly overridden by styling preserved on the Node during parsing. This is a regression reported in issue #298.

Reproduction:
- Parse a document into a Node, e.g.:
  "foo:\n  - 1\n  - 2\n  - 3\nbar: baz\n"
- Configure the Emitter to use flow formatting globally:
  - Emitter::SetSeqFormat(YAML::Flow)
  - Emitter::SetMapFormat(YAML::Flow)
- Stream the Node into the Emitter via operator<<.

Expected behavior:
- The Emitter’s global settings should control the output formatting, producing a flow-style map and flow-style sequence:
  "{foo: [1, 2, 3], bar: baz}"

Actual behavior:
- The emitted output ignores the global flow settings and instead uses the preserved node style from parsing, producing a block-form document:
  "foo:\n  - 1\n  - 2\n  - 3\nbar: baz"

The bug appears specifically when emitting sequences (and potentially maps) that have an associated style coming from the parsed Node. In particular, the emission path that handles sequence start events must not let the node’s stored style override the Emitter’s configured global style. Ensure that when Emitter::SetSeqFormat / Emitter::SetMapFormat have been set, those settings take precedence over any node style derived from Load()/parsing, so that streaming a Node respects the Emitter’s global formatting configuration.
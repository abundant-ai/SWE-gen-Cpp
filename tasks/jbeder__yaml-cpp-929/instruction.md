YAML::Emitter produces invalid/ambiguous YAML when an alias is used as a mapping key. When emitting a map entry whose key is an alias (e.g., Key << Alias("i") << Value << Alias("v0")), the emitter currently outputs the alias key immediately followed by a colon, like:

  *i: *v0

This output can fail to parse when fed back into yaml-cpp’s own Parser (and is rejected by some YAML validators), because the colon can be interpreted as part of the plain scalar unless it is separated correctly. The emitter should instead emit a space before the colon when the key is an alias, producing:

  *i : *v0

The same spacing rule must hold in both block and flow styles.

Reproduction examples that should work after the fix:

1) Emitting a document with anchored scalars and then using aliases as keys and values inside a flow sequence of maps should produce:

Aliases:
 - {&i i: &v0 0}
 - {&i i: &v1 1}
NodeA:
  k: [{*i : *v0}, {*i : *v1}]

Here, each flow map entry must use "*i : *v0" (space before colon) rather than "*i: *v0".

2) Emitting a flow sequence that contains mapping entries directly (still using alias keys) should produce:

NodeB:
  k: [*i : *v0, *i : *v1]

Again, alias keys must be followed by " :" rather than ":".

Expected behavior: the emitted YAML round-trips through yaml-cpp (Dump/Emitter output can be parsed back by Parser without exceptions), and alias keys are emitted with correct spacing before the colon in all supported styles.

Actual behavior: alias keys are emitted as "*alias: value" without the required spacing, leading to parse errors / validator failures even though normal scalar keys ("key: value") work.
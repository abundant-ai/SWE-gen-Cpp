When emitting YAML, aliases used as mapping keys are currently serialized in a way that produces YAML that yaml-cpp’s own parser (and common validators) reject. Specifically, when a map key is an alias created with Alias("name") (e.g., *i), the emitter outputs the key directly followed by a colon with no separating space, like:

    *i: *v0

This is ambiguous because “:” can be interpreted as part of a plain scalar, and the produced YAML is not accepted by the parser. The expected output when an alias is used as a key is to include a space before the colon, i.e.:

    *i : *v0

This must work both for block mappings and for flow contexts where mappings are embedded in sequences. For example, emitting a flow sequence of maps that use aliases as both keys and values should serialize entries like:

    k: [{*i : *v0}, {*i : *v1}]

Additionally, a flow sequence that contains map entries directly should also serialize with the same spacing rule:

    k: [*i : *v0, *i : *v1]

The failure currently manifests as an output mismatch (missing space before ":") and, more importantly, as yaml-cpp failing to parse YAML that it emitted. After the fix, YAML::Emitter should always emit alias keys with a space before the colon so that round-tripping through the parser succeeds, while leaving normal scalar keys unchanged (e.g., "key: value" should remain as-is).
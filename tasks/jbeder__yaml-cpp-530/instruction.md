Users implementing YAML::EventHandler currently cannot retrieve the textual anchor/alias name when parsing YAML. The callbacks expose only an internal numeric anchor_t id (e.g., EventHandler::OnAlias(const Mark&, anchor_t) and the anchor_t argument on OnScalar/OnSequenceStart/OnMapStart), but not the original anchor string such as "a" in "&a" or "*a". This makes it impossible for downstream code to map events back to the YAML anchor name or to answer questions like “what alias name was referenced here?”.

Add back a supported way to access anchor/alias string values during parsing by introducing an optional EventHandler callback:

```cpp
virtual void OnAnchor(const Mark& mark, const std::string& anchorName);
```

Behavior requirements:
- When the parser encounters an anchor definition (e.g., a scalar/sequence/map prefixed with an anchor like `&anchor`), it must invoke `OnAnchor(mark, "anchor")` at the point the anchor is seen.
- This callback must be optional: existing user code that subclasses EventHandler without implementing OnAnchor must continue to compile and run without change.
- The existing event callbacks and their anchor_t ids must continue to behave as before (e.g., OnScalar/OnSequenceStart/OnMapStart and OnAlias still receive the anchor_t id), but users who implement OnAnchor must receive the string name as well.
- The callback should fire for anchors attached to scalars, sequences, and maps.

Example scenario:
- Parsing `&a foo` should result in an OnAnchor callback with anchorName "a" and then the normal scalar event.
- Parsing `&a [1, 2]` should result in OnAnchor("a") and then the normal sequence-start event.
- Parsing `&a {k: v}` should result in OnAnchor("a") and then the normal map-start event.

The goal is that applications using EventHandler can reliably retrieve the anchor/alias string values without changing how existing handlers work.
A new XML parsing option is needed to reduce memory usage in documents with many PCDATA nodes by avoiding creation of separate PCDATA nodes. Add a new parser flag named `parse_embed_pcdata` that, when enabled, stores plain character data (PCDATA) directly in the parent element’s value instead of creating `node_pcdata` children.

Currently, when parsing element content like `<root>hello<child/>world</root>`, the parser represents `hello` and `world` as separate PCDATA child nodes of `root`. With `parse_embed_pcdata` enabled, plain character data should be embedded into the owning element:
- Parsing should not create `node_pcdata` children for plain character data.
- Instead, the parent element’s `value()` should contain the character data that would otherwise be stored in those PCDATA nodes.

This flag must only affect plain character data (PCDATA). It must not change how other node types are represented:
- Comments, CDATA sections, processing instructions (when enabled via existing flags like `parse_pi`), declarations, etc. should continue to produce their corresponding node types as before.
- The existing behavior must remain unchanged when `parse_embed_pcdata` is not set.

Define clear behavior for multiple/segmented character-data runs within the same element:
- If an element would normally receive multiple PCDATA nodes (e.g., because of interleaved child elements), the embedded text must be combined into the element’s value in document order (effectively as if those PCDATA nodes were concatenated).
- If there is no plain character data for an element, its `value()` should remain empty.

The new flag must be supported through the standard parsing entry points (e.g., `xml_document::load_string` and other `load_*` APIs that accept parse flags), and it must interact correctly with existing flags such as `parse_fragment` and `parse_declaration`.

Expected user-visible effects when `parse_embed_pcdata` is enabled:
- `xml_node::value()` on elements that contain plain character data returns that text.
- Iterating children of an element no longer yields `node_pcdata` nodes for plain character data.
- Parsing must still succeed for the same inputs as before; the change is structural, not a parse-error change.

Add coverage to ensure the feature works and does not regress unrelated parse behaviors (including processing instruction parsing when `parse_pi` is enabled), and ensure the default behavior (flag disabled) remains identical to current behavior.
The XML serialization API needs two additional formatting modes that change how attributes and tag closings are written when saving XML.

Currently, calling the document/node save routine with indentation formatting writes all attributes on the same line as the start tag (e.g. `<node attr="1" other="2">`). For workflows like diff/merge of config files, users need a mode where each attribute is written on its own line aligned under the start tag.

Implement a new formatting flag named `format_indent_attributes` that, when passed to the save function (e.g. `doc.save(writer, indent, flags)`), outputs elements so that:

- The element name is written, then a newline.
- Each attribute is written on its own line, prefixed by the current indentation string (one indentation level deeper than the `<node` line), in the same order as in the document, using normal quoting/escaping rules.
- For a normal start tag, the closing `>` should appear immediately after the last attribute on that same line (no extra newline before `>`).

Example expected output for an element with two attributes and nested children:

```xml
<node
	attr="1"
	other="2">
	<child>
		<sub>text</sub>
	</child>
</node>
```

For an empty element (self-closing), the `/>` should appear on the same line as the last attribute:

```xml
<node
	attr="1"
	other="2" />
```

This mode must also apply to a document that includes an XML declaration: the declaration should be written normally, followed by a newline, then the root element formatted with `format_indent_attributes`.

Additionally, implement another formatting flag named `format_indent_full`. This mode is like `format_indent_attributes` but also forces the tag closing delimiter (`>` for start tags and `/>` for empty tags) onto its own separate line aligned with the attribute lines (i.e., at the same indentation level as the attributes), so the closing delimiter line comes after all attributes.

Example for a non-empty element:

```xml
<node
	attr="1"
	other="2"
	>
	<sub />
</node>
```

Example for an empty element:

```xml
<node
	attr="1"
	other="2"
	/>
```

Both new flags must integrate with existing save/formatting behavior:

- Indentation of child nodes should remain consistent with existing `format_indent` behavior.
- With these flags enabled, only the attribute formatting and (for `format_indent_full`) the placement of `>`/`/>` should change; escaping, quoting, and node content handling should remain unchanged.
- The default behavior when no new flag is provided must remain unchanged.

When these flags are missing or incorrectly implemented, users will observe the output staying on one line (attributes not split), or the `>`/`/>` placement not matching the examples above when `format_indent_full` is requested.
When parsing XML content, consecutive text segments (PCDATA) can be split into multiple adjacent text nodes whenever an intermediary construct appears in the source, even if that intermediary construct is configured to be skipped/ignored. This is most visible with comments: if comments are not being parsed (i.e., the parse option for comments is not enabled), comment tokens are ignored but they still cause surrounding text to be emitted as separate adjacent text nodes.

For example, parsing:

```xml
<node>
    Lorem ipsum dolor sit amet,
    consetetur sadipscing elitr, <!-- Some Comment -->
    sed diam nonumy eirmod tempor invidunt <!-- ut labore et dolore magna aliquyam erat-->,
    sed diam voluptua.
</node>
```

currently produces three separate text children under `<node>` when comments are disabled: one for the text before the first comment, one for the text between the comments, and one for the text after the second comment. This happens even though the comments are not present in the DOM.

Expected behavior: if an intermediary node type is not being parsed into the DOM (e.g., comments are disabled), then its presence in the source should not force a text split. Instead, adjacent PCDATA fragments that become adjacent in the resulting DOM should be merged into a single text node. In the example above, with comments disabled, `<node>` should have exactly one text child whose value is the concatenation of all three text fragments (preserving the original whitespace/newlines around where the comments were).

When comments are enabled, behavior should remain unchanged: the DOM should contain text nodes and comment nodes in the correct order (i.e., multiple text nodes separated by comment nodes).

Implement support for merging adjacent PCDATA during parsing when no intermediary nodes are produced, via the intended parsing behavior for the new capability (referred to as `parse_merge_pcdata`). The change should ensure that enabling/disabling parsing of node types (such as comments) does not unexpectedly fragment text content when the skipped nodes do not appear in the final tree.
yaml-cpp’s document parsing has two related correctness issues when loading YAML streams.

1) Empty documents at the end of a multi-document stream are incorrectly skipped.
A YAML stream may contain multiple empty documents separated/terminated by document boundary markers. For example, the stream:

```
...
...
...
```

represents three empty documents. Currently, when parsing such input as a stream of documents, yaml-cpp incorrectly drops trailing empty documents and reports fewer documents than are actually present (e.g., it only yields a single empty document instead of three). The parser should preserve and emit each empty document, including those that occur at the end of the stream.

2) Unexpected leftover tokens after a document are not rejected, causing invalid inputs to be accepted as multiple documents.
Given input such as:

```
[foo]_bar
```

yaml-cpp currently parses this as if it were multiple documents: the first document is the flow sequence `[foo]`, and the remaining `_bar` is treated as another document/scalar. This is incorrect: after completing a document, yaml-cpp should detect that there are unexpected extra tokens remaining on the same document and fail parsing.

When calling `YAML::Load("[foo]_bar")`, yaml-cpp should not successfully return a `Node` representing the sequence `["foo"]`. Instead, it should raise a parsing error (e.g., a `YAML::ParserException`) because there is non-whitespace content trailing immediately after the closing `]` that cannot start a new document without an explicit document boundary.

Fix the parser so that:
- Multi-document parsing yields the correct number of empty documents, including trailing empty documents.
- Single-document loading rejects inputs where, after a document is parsed, the scanner still has unexpected tokens remaining (such as a plain scalar `_bar` immediately following a closed flow sequence), and `YAML::Load` throws a parser error for such inputs.
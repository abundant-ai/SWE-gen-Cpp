yaml-cpp incorrectly handles certain multi-document edge cases when parsing a YAML stream.

1) Empty documents at the end of a stream are skipped
A YAML stream may contain multiple documents separated/terminated by document markers. When the stream consists of multiple empty documents such as:

```
...
...
...
```

yaml-cpp currently returns fewer documents than expected (it effectively collapses/truncates trailing empty documents and only produces a single empty document). The expected behavior is that each document end marker corresponds to an empty document, so the stream above should yield 3 documents, each representing an empty/null document.

This needs to be fixed so APIs that iterate/parse a stream of documents do not drop empty documents at the end.

2) Flow sequence followed by extra characters is parsed as multiple documents instead of being rejected
When parsing a single document like:

```cpp
YAML::Node node = YAML::Load("[foo]_bar");
```

yaml-cpp currently parses this as if it were multiple documents: the first document is the flow sequence `[foo]`, and then the remaining `_bar` becomes another scalar/document. This is incorrect for a single-document load.

Expected behavior: after parsing a complete document, yaml-cpp must validate that there are no unexpected extra tokens remaining in the stream (other than valid document separators/terminators and end-of-stream). For input like `[foo]_bar`, yaml-cpp should not silently accept it as multiple documents; it should raise a parsing error (e.g., throw a `YAML::ParserException`) indicating that unexpected content exists after the end of the document.

After the fix:
- Multi-document parsing must preserve empty documents, including at the end of the stream.
- Single-document parsing via `YAML::Load` must reject inputs where extra non-separator content follows a valid document (e.g., `[foo]_bar`) by throwing `YAML::ParserException` rather than producing an additional document/scalar.
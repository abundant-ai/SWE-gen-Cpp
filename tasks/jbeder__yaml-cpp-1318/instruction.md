Invalid YAML inputs are being accepted as valid by yaml-cpp in multiple scenarios, which can cause downstream applications to mis-handle malformed configuration and potentially consume unbounded resources while processing the resulting node tree. The library should reject these inputs by throwing a parsing exception rather than returning a successfully-parsed Node/sequence.

One reproducible case is an indentation error inside a flow-style sequence used in a mapping value. For example, parsing YAML like:

```yaml
- macro: exclude_commands
  condition:
    (user.uid = 1001 and user.loginuid in (-1, 1001) and proc.exepath = "/usr/bin/script" and proc.args in (
"/usr/local/bin/script_metrics.sh",
    "-c rsync"
    )  )
```

should fail with a parser error (e.g., a YAML::ParserException / YAML::Exception) because the indentation is invalid, but currently it can be accepted.

Another class of invalid input that must be rejected is malformed flow content that looks like comma-separated quoted scalars without being inside a valid YAML collection. For example, attempting to parse:

```yaml
"foo","bar"
```

should raise a parsing exception, but it is currently accepted.

Additionally, parsing multiple documents in a stream must correctly account for empty documents. When parsing a stream that contains empty documents followed by a non-empty document, the empty documents should still be represented in the returned result. For example:

```cpp
const char* docs = R"(
---
---
A
)";
const auto parsed = YAML::LoadAll(docs);
```

`YAML::LoadAll` is expected to return a sequence with size 2 (one entry per `---`), where the first document is empty/null and the second document contains the scalar `"A"`. The current behavior returns 0 documents.

Fix the parser so that these malformed YAML strings are not silently accepted and so that document-stream handling correctly returns empty documents. Ensure the public APIs `YAML::Load`, `YAML::LoadAll`, and `YAML::LoadAllFromFile` (where applicable) consistently throw on invalid YAML and consistently include empty documents in `LoadAll` results.
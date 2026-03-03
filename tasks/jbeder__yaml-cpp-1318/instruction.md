The YAML parser is incorrectly accepting some malformed YAML inputs as valid documents, which can cause downstream applications to misbehave severely. In particular, when given invalid YAML with indentation/structure errors (such as an unterminated/misindented flow sequence inside a mapping), parsing should fail fast with a parser exception, but instead the input can be accepted or lead to pathological behavior in consumers.

Reproduction example (invalid indentation inside a sequence) that should be rejected:

```yaml
- macro: exclude_commands
  condition:
    (user.uid = 1001 and user.loginuid in (-1, 1001) and proc.exepath = "/usr/bin/script" and proc.args in (
"/usr/local/bin/script_metrics.sh",
    "-c rsync"
    )  )
```

Expected behavior: attempting to parse this YAML using the library’s normal loading APIs (e.g., `YAML::Load(...)` / `YAML::LoadAll(...)`) should throw a parsing-related exception (such as `YAML::ParserException`) indicating the YAML is invalid.

Actual behavior: the parser may accept the input (or not error reliably), allowing the program to proceed with an incorrect parse. In some real-world usage (e.g., Falco rules parsing), this can lead to extreme memory consumption and a crash/hang rather than a clean parse error.

Additionally, the parser is accepting invalid “comma-separated strings” that are not valid YAML flow sequences, for example:

```yaml
"foo","bar"
```

Expected behavior: this should be rejected as invalid YAML and cause a parser exception when loaded.

Actual behavior: it is currently accepted as if it were valid YAML.

Finally, loading a stream containing empty documents regressed: a stream consisting of empty documents followed by a non-empty document should produce nodes for the non-empty document(s) rather than returning an empty result set. For example, given this YAML stream:

```yaml
---
---
A
```

Expected behavior: `YAML::LoadAll(docs)` should return a collection of size 2 (two documents in the stream are present, where empty documents are handled correctly and do not cause the entire parse to produce zero documents).

Actual behavior: `YAML::LoadAll(docs)` returns 0 documents for this input.

Fix the parsing logic so that these malformed inputs are rejected with appropriate parse exceptions, and ensure `YAML::LoadAll` correctly returns documents when the stream contains empty documents before a non-empty document. The `Node` loading APIs should continue to behave normally for valid YAML, and invalid YAML should reliably fail rather than being silently accepted.
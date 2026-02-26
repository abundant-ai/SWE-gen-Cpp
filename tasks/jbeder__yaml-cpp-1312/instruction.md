YAML parsing currently treats only '\n' as a line break when scanning input, which breaks parsing for content that uses standalone carriage returns ('\r') as the line ending (classic Mac-style text). As a result, sequences and other multi-line structures can be parsed as if they were on a single line.

For example, loading a document like:

```cpp
auto node = YAML::Load(
  "channels:\r"
  "- my_channel\r"
  "- my_second_channel\r"
);
```

and then evaluating:

```cpp
size_t size = node["channels"].size();
```

should yield `2`, because there are two sequence entries. Currently it yields `1` (or otherwise mis-parses the sequence) because '\r' is not recognized as a newline delimiter.

Update the YAML input handling so that a stream using '\r' as its line break character is parsed correctly, treating '\r' as a valid line break character per YAML 1.2 line break rules. This must work for inputs using only '\r' line endings, and must not break existing behavior for inputs using '\n' or Windows-style '\r\n'.
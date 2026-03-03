YAML parsing incorrectly handles inputs that use carriage return ("\r") as the sole line-break character. When a YAML document uses old-Mac style line endings (CR-only), the loader does not treat "\r" as a newline, causing multiple physical lines to be read as a single logical line and producing incorrect parse results.

Reproduction example:

```cpp
YAML::Node config = YAML::Load(
    "channels:\r"
    "- my_channel\r"
    "- my_second_channel\r"
);
size_t size = config["channels"].size();
```

Expected behavior: `size` should be `2` because `channels` is a sequence with two items.

Actual behavior: `size` is `1` because the parser fails to recognize CR-only line breaks.

`YAML::Load(...)` should accept YAML content where line breaks are any of the YAML-spec line break characters, including:
- LF ("\n")
- CRLF ("\r\n")
- CR ("\r")

After the fix, parsing should behave consistently regardless of whether the input uses LF, CRLF, or CR line endings, so that sequences and mappings separated by CR-only line breaks are tokenized into distinct lines and parsed into the correct node structure.
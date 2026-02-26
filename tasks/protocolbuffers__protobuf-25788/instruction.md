Abseil flag support for protobuf-generated enums currently works for single enum values, but it does not support flags whose type is `std::vector<Enum>`. This prevents users from defining comma-separated lists of enum values on the command line and having them be parsed into a `std::vector` of the enum type.

Extend the Abseil flag marshalling support for protobuf-generated enums so that `std::vector<Enum>` is supported.

When parsing from a string to `std::vector<Enum>`, the input format must be:

```text
VALUE,...
```

That is, zero or more comma-separated enum tokens. The parser must preserve the order of values and must not deduplicate duplicates.

Required behavior:
- Parsing an empty string must succeed and produce an empty `std::vector<Enum>`.
- Parsing a single token like `"FOO"` must produce a vector with one element corresponding to that enum value.
- Parsing multiple tokens like `"FOO,BAR,FOO"` must produce a vector of length 3 with the corresponding values in that exact order (including the repeated `FOO`).
- Serializing (unparsing) a `std::vector<Enum>` back to a string must produce the same comma-separated representation, preserving element order and including duplicates. An empty vector must serialize to the empty string.
- If any token in the comma-separated list is not a valid name or number for the enum type, parsing must fail (and must not silently drop/replace invalid entries).

This should integrate with Abseil flags in the same way that single-enum flag support already does, using the same enum name/number conventions that protobuf’s generated enum utilities currently accept for individual enum values.
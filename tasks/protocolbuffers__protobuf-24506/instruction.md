When generating Kotlin sources from .proto files with code annotation output enabled, the Kotlin generator should embed the full annotation metadata (a serialized google.protobuf.GeneratedCodeInfo) directly into the generated .kt file as an inline comment at the end of the file.

Currently, Kotlin-generated output does not reliably expose this annotation metadata in-band, which prevents downstream tools (e.g., Kotlin Kythe indexers) from retrieving and applying source-to-descriptor annotations.

Update the Kotlin generator so that when protoc is invoked with Kotlin output options that request annotated code generation (e.g., using the standard annotate_code option), the produced .kt file contains a single-line comment of the form:

```text
// google.protobuf.GeneratedCodeInfo: <BASE64>
```

where `<BASE64>` is the base64 encoding of the binary serialization of the google.protobuf.GeneratedCodeInfo message for that generated file. The embedded data must be parseable back into GeneratedCodeInfo after base64 decoding.

The generated annotations contained in that metadata must correctly describe source spans for Kotlin output, including (at minimum) message and field declarations, so that looking up annotations by their descriptor path returns annotations whose `text` matches substrings in the generated Kotlin file and whose semantic values match the expected entity types.

If the inline metadata comment is missing, malformed, not base64, or does not decode into a valid GeneratedCodeInfo, compilation should be considered incorrect. The generator must also ensure the comment is present in the generated Kotlin file content even when multiple output files are produced in a single invocation.
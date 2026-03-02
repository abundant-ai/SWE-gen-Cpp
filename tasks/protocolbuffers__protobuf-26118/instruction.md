The Rust protoc backend currently cannot emit code generation metadata for source annotations in its generated Rust output. A new boolean generator option named `annotate_code` needs to be supported via `--rust_opt=...` so users can request emitting `google.protobuf.GeneratedCodeInfo` metadata into the generated `.rs` file.

When invoking protoc with the Rust generator using an option string like:

`--rust_opt=experimental-codegen=enabled,kernel=cpp,annotate_code=true`

the generated Rust source must include a comment near the end of the file beginning with:

`// google.protobuf.GeneratedCodeInfo `

followed by a base64-encoded wire-format payload and a newline. The payload must be decodable as a `google.protobuf.GeneratedCodeInfo` message.

Default behavior must remain unchanged: if `annotate_code` is not provided at all, no such `// google.protobuf.GeneratedCodeInfo ` comment may appear in the output. If `annotate_code=false` is explicitly provided, the metadata comment must also be absent.

The Rust generator must correctly parse `annotate_code` from `--rust_opt` and propagate it through the generator configuration so code generation can conditionally include or omit the metadata. The option must accept `true` and `false`; invalid values should be treated as an option parsing error (i.e., protoc should fail with an error rather than silently enabling/disabling annotations).
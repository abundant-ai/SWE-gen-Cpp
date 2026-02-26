Formatted error messages in the Java protobuf runtime are currently affected by the JVM’s default locale. This causes exception messages and validation errors to change depending on the machine/user locale (for example, in locales like Turkish, case conversion and formatting can produce different output), making behavior inconsistent and causing failures for code that expects stable, English/ASCII-style messages.

Update the protobuf Java runtime so that any error message built via formatting APIs uses a locale-independent formatter. In particular, any use of `String.format(...)` (and similar formatting calls that accept a locale) used to construct messages for thrown exceptions should use `Locale.ROOT` explicitly.

This needs to apply across the runtime and utilities where formatted exceptions are produced, including:
- UTF-8 validation errors (for example, errors surfaced during `ByteString`/byte parsing and validation routines).
- JSON parsing/printing utilities in `JsonFormat` where invalid input triggers `InvalidProtocolBufferException` or `JsonSyntaxException` with formatted text.
- Lite runtime parsing/validation errors where formatted messages are emitted during reads/parses.

Expected behavior: if the process default locale is changed (e.g., `Locale.setDefault(new Locale("tr", "TR"))`), the text of formatted error messages produced by protobuf should remain identical to the messages produced under `Locale.US`/`Locale.ROOT` for the same inputs.

Actual behavior: under certain non-English locales, formatted error messages differ (due to locale-sensitive formatting/casing), leading to inconsistent exception messages.

After the fix, all formatted error messages produced by protobuf should be deterministic and locale-agnostic by using `Locale.ROOT` for formatting.
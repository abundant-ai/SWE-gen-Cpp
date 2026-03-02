C++ validation code generation currently derives a preprocessor macro identifier from the protobuf base filename by simply uppercasing it. When the base filename contains characters like dashes (e.g., `filename-with-dash.proto`), the generated macro name includes `-`, producing invalid/ambiguous macro definitions and compiler warnings/errors such as:

"warning: ISO C99 requires whitespace after the macro name [-Wc99-extensions]"

This breaks or degrades builds for generated `.pb.validate.h`/`.pb.validate.cc` files.

Update the C++ macro generation logic so that the macro identifier derived from the base proto filename is converted to `SCREAMING_SNAKE_CASE` rather than a naive `UPPER` transform. In particular:

- Any non-identifier separators in the base filename (notably `-`, and generally any character that isn’t an ASCII letter or digit) must be converted into underscores.
- Letters must be uppercased.
- The resulting macro name must be a valid C/C++ preprocessor identifier and must be stable/deterministic.

After the change, generating C++ validation code for a proto named like `filename-with-dash.proto` should no longer produce invalid macro names or the C99 whitespace warning, and the generated headers should compile cleanly under common toolchains (including Clang with `-Wc99-extensions`).
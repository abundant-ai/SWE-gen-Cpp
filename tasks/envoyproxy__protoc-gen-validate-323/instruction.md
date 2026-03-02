Some Envoy deployments rely on a permissive header validation that only rejects the characters CR (\r), LF (\n), and NUL (\0) in header-related configuration fields. After stricter RFC-oriented header constraints were introduced elsewhere, previously valid configs that did not contain \r/\n/\0 but were not fully RFC-compliant started failing validation.

The validation library needs to provide an Envoy-compatible “header safe” regex that mimics Envoy’s `valid()` behavior: it must reject any string containing `\r`, `\n`, or `\0`, and accept other strings (including ones that may not be RFC compliant) as long as they do not include those characters.

Add a new well-known regex option that can be referenced via the existing `string.well_known_regex` rule in `validate.rules`. When a field is annotated with this new well-known regex, generated validators must enforce:

- Valid: strings that do not contain `\r`, `\n`, or `\0`.
- Invalid: strings containing any of `\r`, `\n`, or `\0` anywhere in the value.

This must work consistently across the supported generated targets (at minimum including the Go runtime used by the harness) and be usable in proto definitions similarly to existing well-known regexes like `HTTP_HEADER_NAME` and `HTTP_HEADER_VALUE`.

Example expected behavior:

- A message with `string val` annotated with the new well-known regex should validate successfully for values like `"hello"`, `"x:y"`, or `"not-rfc-but-ok"`.
- Validation must fail for `"bad\rvalue"`, `"bad\nvalue"`, and values containing the NUL character.

If validation fails, it should be reported through the normal validation error mechanism used by the generated code for other `well_known_regex` failures (i.e., the same style of field violation/error you get today when `HTTP_HEADER_NAME` or `HTTP_HEADER_VALUE` does not match).
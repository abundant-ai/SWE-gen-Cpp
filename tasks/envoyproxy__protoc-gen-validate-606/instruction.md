Python users of `protoc-gen-validate` currently only have `validate(msg)` behavior that stops at the first validation failure by raising `ValidationFailed` with a single error message. Add support for a new function `validate_all(msg)` that performs the same validations as `validate(msg)` but accumulates all validation failures and reports them together.

When calling `validate_all(message)` on an invalid protobuf message, it must raise `ValidationFailed` whose string/repr contains multiple validation error messages separated by newline characters (e.g. `"reason1\nreason2\nreason3"`). The order should match the order validations would run in the generated validator code, so the first line of `validate_all`’s error output must be identical to the single error message produced by `validate(message)` on the same input.

When calling `validate_all(message)` on a valid message, it must succeed (no exception) and must be consistent with `validate(message)` (i.e., they must agree on whether a message is valid or invalid).

This needs to work not only for simple scalar field validations (e.g., string/email, numeric range checks), but also for nested/embedded message validation. In particular, if a message contains an embedded message field that fails validation, `validate_all` should include the embedded message’s validation failures in the aggregated output rather than stopping at the first embedded error. The aggregated message should include failures from all invalid fields encountered during validation (including multiple fields being invalid in the same message).

Example expected behavior:

```python
from protoc_gen_validate.validator import validate, validate_all, ValidationFailed

try:
    validate(msg)
except ValidationFailed as e:
    first = str(e)  # a single message

try:
    validate_all(msg)
except ValidationFailed as e:
    all_reasons = str(e)  # multiple lines
    assert all_reasons.startswith(first)
    assert "\n" in all_reasons  # when multiple failures exist
```

Also ensure `validate_all` is part of the public API (`from protoc_gen_validate.validator import validate_all` works) and that its behavior matches `validate` for validity determination while providing aggregated reasons when invalid.
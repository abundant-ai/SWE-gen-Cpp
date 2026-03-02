Google Mock should support selecting the default mock strictness via a command-line flag, but currently there is no way to change the library-wide default mock behavior without changing code. Add support for a new flag `GMOCK_FLAG(default_mock_behavior)` that can be set via `--gmock_default_mock_behavior=<value>` when initializing Google Mock.

When a user calls `testing::InitGoogleMock(&argc, argv)`, the argument parser should recognize `--gmock_default_mock_behavior` and remove it from `argv`/adjust `argc` the same way other `gmock_*` flags are handled. The flag’s value must be reflected in `testing::GMOCK_FLAG(default_mock_behavior)` after initialization.

The flag should control what happens by default when an uninteresting call occurs on a mock (i.e., a call for which there is no active expectation). The selectable behaviors must include the existing Google Mock behaviors (corresponding to “nice”, “naggy”, and “strict” handling):

- A “nice” mode that does not warn/fail on uninteresting calls.
- A “naggy” mode that emits warnings for uninteresting calls.
- A “strict” mode that treats uninteresting calls as failures.

Expected behavior:
- With no `--gmock_default_mock_behavior` provided, behavior remains exactly the same as today (backward compatible default).
- Providing `--gmock_default_mock_behavior=nice` makes the default uninteresting-call handling equivalent to `NiceMock`.
- Providing `--gmock_default_mock_behavior=naggy` makes the default uninteresting-call handling equivalent to `NaggyMock`.
- Providing `--gmock_default_mock_behavior=strict` makes the default uninteresting-call handling equivalent to `StrictMock`.

Invalid values should be handled robustly: initialization should not crash, and the flag should not silently put the framework into an undefined state. It should either keep the existing default behavior or report a clear error consistent with how other invalid `gmock_*` flags are handled.

This must integrate with existing `testing::Mock` behavior and the framework’s reporting mechanisms so that the chosen default mock behavior reliably affects mock objects’ uninteresting-call handling throughout the process after `InitGoogleMock()` is called.
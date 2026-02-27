When parsing .proto files that use editions and feature sets, feature-support validation is currently inconsistent: validation is applied in some cases (typically for resolved features) but not applied (or applied differently) when the same information is expressed via options. This allows unsupported feature values to slip through proto parsing in certain syntactic forms, and it can also produce confusing or missing diagnostics.

The parsing/compilation pipeline needs a generalized validation step that checks feature support uniformly for both (a) explicit features and (b) options that map onto feature behavior. The validation should be performed during proto parsing/descriptor construction so that invalid/unsupported feature usage fails early with a clear error.

Implement and/or generalize `ValidateFeatureSupport` so it can validate both Options and Features during proto parsing. The validation should:

- Reject proto definitions that enable or set a feature not supported for the selected `Edition`.
- Work whether the feature is specified directly via feature syntax or indirectly via relevant options.
- Return an `absl::Status` / `absl::StatusOr` failure with `absl::StatusCode::kFailedPrecondition` when unsupported features are encountered.
- Provide an error message that clearly indicates that the feature/option is not supported (the message should include enough identifying detail to understand what was unsupported, and be stable enough to assert against in matching).

Reproduction example (conceptual): create a `FeatureResolver` via `FeatureResolver::CompileDefaults(...)` and `FeatureResolver::Create(edition, defaults)`, then parse/compile a proto that sets a feature (or a corresponding option) outside what the defaults/extensions declare as supported for that edition. Instead of succeeding, parsing/compilation should fail with a failed-precondition status describing the unsupported feature usage.

The expected behavior is that unsupported feature usage is rejected consistently regardless of whether it appears as features or options; the current behavior allows some unsupported cases to pass or to be validated only in one representation.
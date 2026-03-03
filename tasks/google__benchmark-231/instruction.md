The benchmark library’s complexity feature needs to support custom complexity functions specified as lambda expressions, and the generated complexity reports must include the computed complexity values (not just the fitted coefficient).

Currently, complexity can only be selected from a fixed set of built-in complexity functions. Users should be able to provide a custom complexity function using a lambda (e.g., N/2, 2**N, or other user-defined growth models) when configuring benchmark complexity reporting. When a benchmark is configured to use a custom complexity function, the framework should use that function when computing the per-iteration complexity values used for fitting, and it should produce a correct complexity estimate and coefficient.

In addition, complexity reporting in CSV and JSON formats is incomplete: these outputs currently only include the coefficient (and related fields) but do not include the actual complexity value evaluated for the benchmark’s problem size. CSV and JSON reporters should be updated so that when complexity results are present, the output includes both:

- the coefficient (as before), and
- the computed complexity value for the reported input size (i.e., the complexity function evaluated at the benchmark’s “N” / problem size).

There is also a type correctness issue: the field representing the benchmark’s complexity input size (commonly referred to as “complexity_n”) must be able to represent large values consistently across platforms. It should use an unsigned size type (size_t) rather than int so that large problem sizes do not overflow or truncate, and so that the computed complexity values are based on the correct input.

After implementing the above, complexity results must be consistent across all reporters (console, CSV, and JSON). In particular, when the same benchmark run produces a complexity estimate, each reporter should present the same underlying values (including the computed complexity value) and formatting should not omit complexity-specific fields in CSV/JSON.

Example scenarios that must work:

- A benchmark configured with a custom lambda complexity like N/2 should produce a complexity report where the complexity value corresponds to N/2 for the benchmark’s problem size.
- A benchmark configured with a custom lambda complexity like 2**N should compute complexity values correctly for the provided N and include those computed values in JSON and CSV outputs.
- Very large complexity input sizes should not overflow or become negative; computations and output should reflect the correct size_t value.
Human-readable formatting for benchmark counter values does not consistently honor the selected thousands base (SI vs IEC). When a counter is configured to use base-1024 formatting, the output should use IEC-style suffixes (Ki, Mi, etc.) and the numeric scaling should be computed using 1024; when configured for base-1000, it should use SI suffixes (k, M, etc.) and scaling by 1000. Currently, the choice of SI/IEC unit is not being correctly passed through the formatting path, so counters that explicitly request base-1024 can be rendered using the wrong suffix and/or wrong scaling.

The issue is visible when reporting counters around common boundaries like 1,000,000 and 1,048,576:

- A counter value of 1,000,000 with base-1000 should format as "1M".
- A counter value of 1,000,000 with base-1024 should format as approximately "976.562Ki" (i.e., 1,000,000 / 1024 ~= 976.5625) and must use the "Ki" suffix.
- A counter value of 1,048,576 (1024*1024) with base-1024 should format exactly as "1Mi".
- A counter value of 1,048,576 with base-1000 should format as approximately "1.04858M" and must use the "M" suffix (not "Mi").

Fix the human-readable formatting and counter reporting so that the `benchmark::Counter` configuration (including `benchmark::Counter::OneK::kIs1000` vs `benchmark::Counter::OneK::kIs1024`, and the default behavior) is correctly carried through to the code that produces the final human-readable string. This should apply consistently to console output and machine-readable outputs that include the human-readable counter text.
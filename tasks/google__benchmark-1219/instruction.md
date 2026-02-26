Benchmark aggregate statistics are currently hardcoded to be reported in time units, which makes some statistics misleading or hard to interpret (e.g., standard deviation is shown as a duration, requiring the reader to also compare against the mean/median). The library needs to support aggregate statistics whose natural unit is a percentage (e.g., relative standard deviation / coefficient of variation), and the reporting outputs must correctly label and format such statistics.

When a benchmark run produces aggregate results like complexity outputs (e.g., “BigO” and “RMS”), the “RMS” aggregate should be treated as a percentage-valued metric rather than a time-valued metric.

Current behavior: aggregate results are serialized and labeled as time-based. In JSON output, aggregate entries use an aggregate unit that does not distinguish between time and percentage. In console output, percentage-valued aggregates are not consistently formatted with a percent sign, and CSV output does not clearly represent that an aggregate is a percentage.

Required behavior:

1) Add support for an aggregate/unit type representing “percentage” in addition to the existing “time” behavior for aggregate statistics.

2) For complexity results:
- The “BigO” aggregate remains time-based and must have aggregate_unit set to "time" in JSON.
- The “RMS” aggregate must have aggregate_unit set to "percentage" in JSON, and its displayed console value must include a trailing percent sign (e.g., "2 %" with flexible spacing).

3) Output formatting must be consistent across output formats:
- Console output: percentage aggregates must render with a % suffix.
- JSON output: percentage aggregates must include "aggregate_unit": "percentage".
- CSV output: percentage aggregates must be emitted in a way that does not incorrectly imply the unit is time (and must match the existing CSV column expectations for aggregate rows).

4) Existing time-based aggregates such as "mean", "median", and "stddev" must continue to report aggregate_unit as "time" in JSON and keep their existing console/CSV formatting.

The change should make it possible for new or existing statistics to explicitly choose between time and percentage units, so that statistics like relative standard deviation (σ/|μ| expressed in %) can be added without being mislabeled or formatted as a duration.
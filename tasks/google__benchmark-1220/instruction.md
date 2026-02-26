Benchmark aggregate output is missing a normalized variability metric. Users want a coefficient of variation (CV), also known as relative standard deviation, to complement the existing mean/median/stddev aggregates.

Currently, when benchmarks are run with repetitions and aggregate reporting enabled (e.g., using APIs like ReportAggregatesOnly() or DisplayAggregatesOnly()), the emitted aggregate rows include suffixes such as "_mean", "_median", and "_stddev", but there is no "_cv" aggregate. This makes it hard to compare run-to-run variability across benchmarks of different absolute durations.

Implement a new statistic function named StatisticsCV(values) that computes the coefficient of variation as:

CV = StatisticsStdDev(values) / StatisticsMean(values)

and returns a double.

It must satisfy these behaviors:
- For identical values (e.g., {101, 101, 101, 101}), StatisticsCV returns 0.0.
- For values {1, 2, 3}, StatisticsCV returns 0.5 (since stddev=1 and mean=2).
- For values {2.5, 2.4, 3.3, 4.2, 5.1}, StatisticsCV returns 0.32888184094918121.

In addition, integrate this new CV statistic into the benchmark repetition aggregates so that when repetitions are used, a new aggregate entry is produced with the name suffix "_cv" alongside the existing "_mean", "_median", and "_stddev" aggregates.

When using aggregate-only modes, the output should include exactly one aggregate entry named like:
- "<benchmark-name>/repeats:<N>_cv"

and it should appear in the same contexts where mean/median/stddev aggregates appear.

The CV metric is unitless and should be presented as a percentage in human-readable console output (e.g., showing values like "1.44 %"), while still being properly represented in structured outputs (e.g., JSON) with the correct naming so downstream tooling can detect it. The implementation should ensure the aggregate appears for both real_time and cpu_time contexts similarly to other aggregates.
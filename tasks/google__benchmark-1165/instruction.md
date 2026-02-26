When running benchmarks and emitting results (especially JSON), there is currently not enough information to consistently order/sort benchmark instances that belong to the same benchmark family when execution order differs from registration order. Tools can use the existing per-run metadata like "family_index" to group families, but there is no stable index to enumerate individual instances within a family.

Add a new per-family instance index that is reported for every benchmark run/record. In the JSON output for each result object, include an integer field named "per_family_instance_index" that indicates the zero-based position of that benchmark instance within its family. This index must be stable and deterministic with respect to the family’s instances, so that even if benchmarks are executed in a different order, the results can still be sorted correctly within each family.

Expected behavior:
- JSON output objects that represent benchmark runs must include both:
  - "family_index": an integer identifying the family
  - "per_family_instance_index": a zero-based integer identifying the instance within that family
- For a family with only a single instance (e.g., a benchmark without arguments), "per_family_instance_index" must be 0.
- For benchmarks that produce additional aggregate outputs (e.g., complexity BigO and RMS aggregate records), those aggregate records must also include the same "family_index" and the correct "per_family_instance_index" for the underlying benchmark instance they summarize.
- This field must appear alongside the other standard per-run JSON fields such as "name", "run_name", "run_type", "repetitions", "repetition_index" (when applicable), "threads", "iterations", and timing fields.

Actual behavior:
- JSON output does not include "per_family_instance_index", so multiple instances within the same family cannot be reliably ordered by consumers when execution order is not sequential.

Implement the per-family instance indexing so that all benchmark result records (including iteration runs and aggregates) provide "per_family_instance_index" correctly and consistently.
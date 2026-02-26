JSON output from the benchmark library is missing a stable identifier that ties together runs belonging to the same benchmark family. This becomes a problem when runs are interleaved (for example, due to run interleaving features): entries from the same family may be far apart in the JSON array, making it difficult for downstream tools to regroup related results deterministically.

Add support for a new numeric field named "family_index" that is emitted for each reported run in the JSON output. The value must identify the benchmark family among the set of families that are actually executed after applying any benchmark filters.

The following behavior is required:

When producing JSON output for any benchmark run (including iteration runs and aggregate runs such as complexity BigO/RMS), each JSON object representing a run must include a line/field like:

"family_index": 0,

placed alongside the other top-level run metadata (e.g., near "name", "run_name", "run_type", etc.).

The "family_index" must be consistent for all runs that belong to the same benchmark family (e.g., the repeated runs for the same benchmark, and any aggregate outputs associated with that benchmark) and must be zero-based.

The mapping used for "family_index" must count only the families that were filtered-in and actually run. For example, if three families exist but the second one is filtered out, the remaining two families (originally first and third) must receive family_index values 0 and 1, not 0 and 2.

Additionally, when using a custom reporter derived from benchmark::ConsoleReporter, the reported benchmark::Run objects must expose the computed family_index so that ReportRuns(const std::vector<Run>&) can read it (e.g., report[0].family_index) and infer how many families ran.

Currently, JSON output does not include "family_index" and reporters/Run metadata do not provide the needed stable family identifier under filtering/interleaving; implement the missing propagation so that tools post-processing JSON can reliably regroup runs by family even when run order differs from family order.
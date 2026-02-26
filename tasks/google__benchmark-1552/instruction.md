The Linux perf-events integration currently limits `PerfCounters` to at most 3 performance counters per measurement, which is overly restrictive for users who want to collect many counters in a single benchmark run. This hard limit should be removed so callers can request an arbitrary number of counters, while still respecting the kernel limitation that only a small number of hardware counters can be active in a single perf-event group.

When `benchmark::internal::PerfCounters::Create(std::vector<std::string>)` is called with more than 3 valid counter names, it should return a valid `PerfCounters` instance as long as the requested events are supported and the list is otherwise valid. The implementation must support creating multiple perf-event groups internally when needed (e.g., when hardware events exceed the group capacity), and `PerfCounters::Snapshot(PerfCounterValues*)` must correctly read and aggregate values from all groups into the single `PerfCounterValues` object.

`PerfCounterValues` should represent the full set of requested counters (size equals the number of requested events). A snapshot must fill all indices with the corresponding counter readings, and repeated snapshots must be monotonically increasing for counters like `"CYCLES"`, `"BRANCHES"`, and `"INSTRUCTIONS"` when run under normal conditions.

Input validation behavior must remain strict:
- `PerfCounters::Create({})` must be invalid.
- `PerfCounters::Create({""})` must be invalid.
- `PerfCounters::Create({"not a counter name"})` must be invalid.
- If any element in the list is empty or unsupported, the overall result must be invalid (even if other names are valid).

Platform behavior must be handled gracefully:
- `PerfCounters::Initialize()` should indicate whether perf counters are supported on the current platform.
- If perf counters are not supported, attempts to initialize and/or create counters should fail cleanly (no crashes), and callers should be able to detect unsupported operation via the existing support indicator/return values.

Overall, the API should allow “unlimited” counters from the caller’s perspective, while internally splitting into multiple groups as needed and ensuring `Snapshot` returns a coherent single vector of values corresponding to the originally requested event order.
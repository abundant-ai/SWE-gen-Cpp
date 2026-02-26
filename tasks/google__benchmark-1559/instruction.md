Performance counter handling has incorrect and inconsistent semantics around initialization, creation, and partial failure. The library exposes a performance counter API via benchmark::internal::PerfCounters and related types (PerfCountersMeasurement, PerfCounterValues). Several user-visible behaviors need to be corrected.

1) PerfCounters::Create() must be resilient to invalid/unsupported counter names. When PerfCounters are supported and PerfCounters::Initialize() succeeds, calling PerfCounters::Create() with an empty list, empty strings, or unknown counter names should not produce an “invalid” object or cause a hard failure. Instead, Create() should drop unsupported/invalid counters and return an object whose num_counters() reflects only the remaining valid counters. For example:
- PerfCounters::Create({}).num_counters() should be 0
- PerfCounters::Create({""}).num_counters() should be 0
- PerfCounters::Create({"not a counter name"}).num_counters() should be 0
- PerfCounters::Create({"BRANCHES", "", "CYCLES"}).num_counters() should be 2 and names() should return {"BRANCHES", "CYCLES"}
- PerfCounters::Create({"INSTRUCTIONS", "not a counter name", "CYCLES"}).num_counters() should be 2 and names() should return {"INSTRUCTIONS", "CYCLES"}
- If a bad counter is appended at the end of an otherwise valid list, it should be ignored (e.g. Create({"CYCLES","BRANCHES","INSTRUCTIONS","MISPREDICTED_BRANCH_RETIRED"}) should keep 3 counters and names() should include only the three known ones).

2) Create() must not invalidate the entire set of counters if one counter fails to open after validation. A partial failure (e.g., one perf event can’t be opened due to permissions or kernel limitations) should result in that counter being excluded while keeping the others usable. The resulting num_counters() and names() must correspond to the counters that actually remain enabled.

3) The previous “validity” query (PerfCounters::IsValid()) is no longer part of the expected semantics. Code paths that previously relied on IsValid() should instead treat “no counters remain” (num_counters()==0) as the signal that perf counters are effectively unavailable for that benchmark run.

4) Perf counters must be created and shared with benchmark runners in a way that avoids static/global sharing across independent runs. PerfCounters should be created once at the beginning of the benchmark execution flow (at the top of RunBenchmarks()), then a single PerfCountersMeasurement instance should be shared with all BenchmarkRunner instances created for the run. This should prevent cross-run state leakage while ensuring all runners in the same run use the same measurement infrastructure.

5) Initialization behavior must remain consistent across supported and unsupported platforms:
- If PerfCounters::kSupported is false, PerfCounters::Initialize() should return false.
- If PerfCounters::kSupported is true, PerfCounters::Initialize() should succeed and PerfCounters::Create({"CYCLES"}).num_counters() should be 1.

Implement the above so that counter creation/filtering, names()/num_counters() reporting, and runner/measurement plumbing behave consistently, including when some requested counters are invalid or fail to open.
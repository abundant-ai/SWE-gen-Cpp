Google Benchmark user counters support modifiers that change how a counter is interpreted (for example, reporting as a rate). Currently, it’s possible to answer questions like “items processed per second”, but it’s not possible to ask the inverse question, “seconds per item” (or more generally, invert the computed counter value) while still using the existing counter modes such as iteration-invariant rate.

A new counter modifier is needed: `benchmark::Counter::kInvert`.

When a user constructs a counter like:

```cpp
state.counters["calc"] = benchmark::Counter(
    calculations_per_iteration,
    benchmark::Counter::kIsIterationInvariantRate | benchmark::Counter::kInvert);
```

the counter should be computed exactly as it would be without `kInvert` (including applying any rate/iteration invariance semantics), and then the final numeric result must be inverted (i.e., replaced with `1.0 / value`). This inversion must be applied after all other counter transformations, regardless of the order in which flags are combined.

Expected behavior:
- `kInvert` can be OR’ed with other `benchmark::Counter::Flags`.
- Inversion happens last, so `kInvert | kIsIterationInvariantRate` and `kIsIterationInvariantRate | kInvert` produce identical output.
- The inverted value is what appears in all output formats (console, JSON, CSV) for that counter.

Edge cases:
- If the final value to be inverted is 0, the library must not crash or emit undefined behavior (e.g., division-by-zero). It should produce a sensible result consistent with the project’s existing handling of non-finite counter values (for example, inf/NaN handling) and remain serializable in JSON/CSV.

This change should make it possible to express things like “time per item” by first expressing “items per second” using existing rate flags and then inverting it via `kInvert`.
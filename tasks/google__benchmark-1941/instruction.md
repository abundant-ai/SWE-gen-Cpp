When a custom `benchmark::MemoryManager` is registered and a benchmark is run with multiple repetitions, memory statistics reported per repetition can become corrupted. The runner appends each repetition’s `MemoryManager::Result` into a growable container and stores a pointer/reference to the newly appended element for later use. If the container grows and reallocates (e.g., `std::vector` auto-resizing), previously stored pointers/references become dangling. Subsequent reads/writes through those invalid pointers can lead to incorrect values in the final reported `memory_result` fields (for example in JSON output), and in some cases can trigger invalid pointer dereferences.

This only shows up when the number of repetitions is greater than 1 (more reliably with 3+ repetitions), because reallocation is more likely as results accumulate.

Fix the benchmark execution/reporting flow so that `MemoryManager::Result` storage remains stable across all repetitions, or so that any references to stored results remain valid even if the underlying container grows. After the fix, running a benchmark with `Benchmark::Repetitions(N)` and `Benchmark::Iterations(1)` while a `MemoryManager` is registered must reliably produce one independent `MemoryManager::Result` per repetition, and each repetition’s reported values must match what `MemoryManager::Stop(Result&)` wrote for that repetition.

Concretely, if a `MemoryManager` increments its counters each time `Stop(Result&)` is called (e.g., `num_allocs += 1`, `max_bytes_used += 2`, `net_heap_growth += 4`, `total_allocated_bytes += 10` after writing the current values into `result`), then for `N` repetitions the reported per-repetition memory results must be:

- repetition i: `num_allocs == i`
- repetition i: `max_bytes_used == i * 2`
- repetition i: `net_heap_growth == i * 4`
- repetition i: `total_allocated_bytes == i * 10`

Additionally, if no `MemoryManager` is registered, running the same benchmark should not produce any memory results for repetitions (i.e., no per-repetition `memory_result` data should be reported/collected).
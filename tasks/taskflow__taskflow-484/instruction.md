The parallel reduction API is missing support for a binary transform-reduce style algorithm and needs to be implemented so users can compute reductions correctly over iterator ranges in a Taskflow graph.

When a user builds a task graph that computes a sequential reference reduction over a subrange [beg, end) and then schedules a parallel reduction task over the same range using the Taskflow reduce API, the parallel result must match the sequential one for many subrange sizes and different partitioning strategies.

Implement/finish the Taskflow reduction entry point so the following usage works reliably:

- A task sets up two iterators `beg` and `end` (e.g., pointing into a `std::vector<int>`) and computes a sequential reduction result `smin` over `[beg, end)` using `std::min`.
- Another task is created via `taskflow.reduce(std::ref(beg), std::ref(end), pmin, [](int& l, int& r){ return std::min(l, r); }, partitioner)` and is made to run after the setup task.
- After execution, `pmin` must equal `smin` and must not remain at the identity initializer value.

Requirements:
- `taskflow.reduce` must accept begin/end iterators passed via `std::ref(...)` (i.e., support iterator references that are assigned at runtime in a preceding task).
- It must work for subranges of varying lengths (including very small ranges like length 1) and for different partitioner configurations (including guided partitioning with various chunk sizes).
- It must produce deterministic correctness: the reduction operator is associative/commutative in the provided scenario (`min`), and the parallel result must match the sequential reference.
- It must work correctly under different executor thread counts (1 or more).

If the range is empty, the behavior should be well-defined (either leave the result unchanged or define an identity-based result), but for non-empty ranges the result must be updated to the correct reduction value.
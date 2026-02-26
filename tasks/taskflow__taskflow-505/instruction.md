When using Taskflow’s parallel algorithms (notably for_each, for_each_index, transform, and find_if), there is currently no built-in way to run a small RAII-style prologue/epilogue around each scheduled chunk/task created by these algorithms. This makes it difficult and inefficient to propagate and restore per-thread CPU state (e.g., floating point exception/FPU configuration) or to centralize exception capture. Users are forced to put expensive state-setup logic inside the loop body (executed once per element) or create ad-hoc wrappers that don’t reliably apply at chunk granularity.

Add support for an optional callable “task wrapper” parameter to these algorithms so that the wrapper is invoked once per chunk/task, and the wrapper receives a callable representing the actual chunk work to execute. The wrapper must be able to run code before and after invoking the chunk work (e.g., setting thread-local/FPU state before, restoring it after). A typical usage should work like:

```cpp
auto task_wrapper = [&](auto&& task) {
  // prologue: apply context
  task();
  // epilogue: restore context
};

taskflow.for_each_index(0, 100, 1, body, tf::StaticPartitioner(1), task_wrapper);
```

The same pattern must be supported for:
- for_each_index(begin, end, step, body, partitioner, task_wrapper)
- for_each(begin_iter, end_iter, body, partitioner, task_wrapper)
- transform(input_begin, input_end, output_begin, op, partitioner, task_wrapper) (and any supported transform overloads)
- find_if(begin_iter, end_iter, predicate, partitioner, task_wrapper) (and any supported find/find_if style overloads)

Expected behavior:
- The wrapper is called once per scheduled chunk/task created by the algorithm, not once per element.
- The wrapper must execute on the same worker thread that runs the chunk work, so that thread-local state changes in the wrapper affect the loop body inside that chunk.
- The wrapper must be able to enforce balanced setup/teardown even if the chunk work exits early (e.g., due to algorithm logic) by relying on RAII in the wrapper.
- For static partitioning with chunk size 1, wrapper call count should match the number of worker threads participating (i.e., chunk tasks created by the scheduler for that run), and every element processed by the algorithm should observe the context set by the wrapper.
- For dynamic partitioning, wrapper call count should be less than or equal to the number of worker threads (since fewer chunk tasks may be spawned), but every processed element must still observe the context set by the wrapper.

Concrete scenario that must work:
- A wrapper sets a thread-local “context value” before running the chunk task and resets it afterward.
- The loop body reads that thread-local value and writes it into an output array.
- After execution, every element in the output array must contain the value set by the wrapper (demonstrating that the wrapper applied for every chunk), and the wrapper’s call count must reflect chunk-level invocation rather than per-element invocation.

Additionally, the wrapper must support use cases like exception capture:

```cpp
std::exception_ptr ep;
auto task_wrapper = [&](auto&& task) {
  try { task(); }
  catch(...) { ep = std::current_exception(); }
};
```

So the wrapper’s callable argument must be invoked by the wrapper (not by the algorithm directly), and the algorithm must remain correct when a wrapper is provided (no missed work, no double execution, and correct completion/wait semantics).
Currently, custom benchmark setup/teardown callbacks are restricted to function-pointer-like types, which prevents using capturing lambdas, functors, or other callable objects when registering benchmarks dynamically (e.g., via RegisterBenchmark) and needing to “carry” per-benchmark parameters into Setup and Teardown.

Update the benchmark API so that Benchmark::Setup(...) and Benchmark::Teardown(...) accept a general callable type based on std::function with the signature void(const benchmark::State&). Expose this callback type as benchmark::callback_function.

After the change, the following usage patterns must work correctly:

- Passing a capturing lambda to bm->Setup(...) and bm->Teardown(...), both by copy and by move, and having the callbacks invoked exactly once each when running the benchmark via RunSpecifiedBenchmarks(...).
- Passing a benchmark::callback_function (std::function wrapping a callable) to bm->Setup(...) and bm->Teardown(...), both by copy and by move, and having the callbacks invoked exactly once each during a run.
- Passing a functor object (a type with operator()(const benchmark::State&)) to bm->Setup(...) and bm->Teardown(...), with the functor being invoked as setup and teardown.

The callbacks must be stored and invoked by the benchmark framework at the appropriate times (setup before the benchmark run and teardown after), and must remain valid regardless of whether the user provided the callable as an lvalue (copied) or rvalue (moved).
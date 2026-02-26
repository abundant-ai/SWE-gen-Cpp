Benchmark complexity reporting is unreliable and sometimes incorrect in two related scenarios.

First, complexity classification for benchmarks declared with `->Complexity()` is flaky in noisy environments. A benchmark intended to be O(1), such as one registered like:

```cpp
BENCHMARK(BM_Complexity_O1)->Range(1, 1<<18)->Complexity();
```

can intermittently print a Big-O line that reports `lgN` (or `lg(N)`) rather than a constant complexity. This happens when later measurements run faster than earlier ones due to CPU load variability, causing the fitted model to pick a logarithmic curve. The output can look like:

```
BM_Complexity_O1_BigO  163.31 lgN  389.19 lgN
```

Expected behavior: a benchmark whose per-iteration cost does not depend on `N` should consistently be classified as constant complexity (reported as `1`, i.e., constant) and should not spuriously switch to `lgN`/`lg(N)` due to measurement noise.

Second, complexity calculation is wrong when a benchmark uses manual timing. If a benchmark uses `UseManualTime()` and reports its own timing (manual “real time”), then `->Complexity()` should compute Big-O based on that manual time. Currently, the Big-O calculation is based on CPU time instead of the manual time, which yields incorrect complexity results and/or incorrect Big-O output.

Expected behavior: when `UseManualTime()` is enabled, complexity fitting and the reported Big-O / RMS values must be derived from the manually reported timing values (the same notion of time that appears as the benchmark’s measured time), not from CPU time.

Fix the library so that complexity fitting is stable for O(1) style benchmarks under noise and so that manual timing is correctly respected by complexity reporting. The final Big-O output should be deterministic enough for CI (no spurious `lgN`/`lg(N)` classification for constant-time benchmarks) and should use manual timing when provided.
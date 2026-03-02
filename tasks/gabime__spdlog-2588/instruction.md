ThreadSanitizer on Ubuntu 22.04 with GCC 11.x reports many warnings (notably “data race” and “double lock of a mutex”) when using spdlog’s async logging that relies on `spdlog::details::mpmc_blocking_queue`. The warnings are triggered around `mpmc_blocking_queue::dequeue_for`, which currently uses `std::condition_variable::wait_for` for timed waits.

This is widely believed to be caused by a GCC libstdc++/tsan issue (GCC bug 101978) where `std::condition_variable::wait_for` can produce false-positive TSAN reports. In practice, users see large volumes of TSAN warnings when running even simple async-logger code such as:

```cpp
spdlog::init_thread_pool(6000, 1);
std::vector<spdlog::sink_ptr> sinks = {
  std::make_shared<spdlog::sinks::rotating_file_sink_mt>("current.log", 2000000, 1),
  std::make_shared<spdlog::sinks::stdout_color_sink_mt>()
};
auto logger = std::make_shared<spdlog::async_logger>(
  "tsan", sinks.begin(), sinks.end(), spdlog::thread_pool(),
  spdlog::async_overflow_policy::block);
logger->info("just a log");
spdlog::shutdown();
```

The queue should provide a way to block indefinitely for work without relying on `wait_for`, and `dequeue_for` should avoid using `std::condition_variable::wait_for` in a way that triggers these TSAN reports.

Implement a blocking dequeue API on `spdlog::details::mpmc_blocking_queue` (e.g. `dequeue(T& item)`), which waits indefinitely until an item is available and then pops it. Update the thread-pool/async logging path to use this indefinite blocking dequeue so the worker thread does not wake up periodically (e.g. every ~10 seconds) when there is no work.

At the same time, keep `dequeue_for(T& item, std::chrono::milliseconds timeout)` semantics intact:
- When called on an empty queue with `timeout == 0ms`, it must return `false` quickly (no noticeable blocking).
- When called on an empty queue with a positive timeout (e.g. ~250ms), it must block approximately that duration and then return `false`.
- When called on a non-empty queue, it must pop an item and return success without waiting.
- For edge cases like a queue constructed with size 0, `enqueue_nowait` should not crash and should increment the overrun counter, while `dequeue_for(..., 0ms)` should return `false`.

After these changes, async logging under TSAN with GCC 11.x should no longer emit the spurious “data race” / “double lock of a mutex” warnings originating from timed waits in the queue implementation, and idle thread-pool worker threads should not wake up periodically just to re-check the queue when no messages are pending.
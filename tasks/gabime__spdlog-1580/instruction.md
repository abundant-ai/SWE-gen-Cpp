`spdlog::sinks::rotating_file_sink` currently does not support customizing how rotated log filenames are generated. Users can only get the built-in naming scheme like `output.1.log` (or `basename.N` when there is no extension), which is insufficient for cases where a different rotated filename format is required (for example `output1.log` or `output_custom.log`).

The sink should support providing a custom filename calculator type, similar to how `spdlog::sinks::daily_file_sink` supports custom calculators. A user should be able to instantiate a sink like:

```cpp
struct custom_rotating_file_name_calculator {
    static spdlog::filename_t calc_filename(const spdlog::filename_t &filename, std::size_t index);
};

using sink_type = spdlog::sinks::rotating_file_sink<std::mutex, custom_rotating_file_name_calculator>;
auto logger = spdlog::create<sink_type>("logger", "test_logs/rotating", 5 * 1024, 1);
logger->info("Hello World!");
logger->flush();
```

Expected behavior:
- `rotating_file_sink` must compile and work when instantiated with a second template parameter that provides `static calc_filename(const spdlog::filename_t&, std::size_t)`.
- When rotation occurs (or when checking the current output file), the sink must use the provided calculator to determine the actual file name to write to / count messages in.
- The default behavior must remain unchanged when using the default calculator (`spdlog::sinks::rotating_filename_calculator`).

The default calculator behavior must remain:
- `spdlog::sinks::rotating_filename_calculator::calc_filename("rotated.txt", 3)` returns `"rotated.3.txt"`.
- `spdlog::sinks::rotating_filename_calculator::calc_filename("rotated", 3)` returns `"rotated.3"`.
- `spdlog::sinks::rotating_filename_calculator::calc_filename("rotated.txt", 0)` returns `"rotated.txt"` (index 0 should not add a suffix).

With a custom calculator that ignores the index and appends a custom suffix before the extension (e.g. `basename_custom.ext`), creating a rotating logger with basename `"test_logs/rotating"` should result in logs being written to `"test_logs/rotating_custom"` (and `"test_logs/rotating_custom.<ext>"` when an extension is present), such that after writing and flushing 10 messages, reading that computed filename shows 10 messages.

Currently, attempting to use `rotating_file_sink<std::mutex, CustomCalculator>` either fails to compile or the sink continues to use the built-in `rotating_filename_calculator` instead of the custom one, preventing custom rotated naming schemes. This needs to be fixed so the custom calculator is honored consistently, while preserving the existing default naming behavior.
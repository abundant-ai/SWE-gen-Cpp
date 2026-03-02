When creating file-based loggers, spdlog currently treats the provided `filename`/base name as a stem and silently appends a hardcoded `.txt` extension in some cases. This leads to unexpected paths such as `mylog.txt.txt` when callers pass a full filename (including extension) to APIs like `spdlog::rotating_logger_mt(...)`. The parameter is named `filename`, so callers expect the string to be used as the complete path to the log file, without spdlog altering it by adding `.txt`.

Reproduction example:
```cpp
auto logger = spdlog::rotating_logger_mt("logger", "logs/mylog.txt", 1024 * 1024, 1);
logger->info("hello");
logger->flush();
```
Expected behavior: logs are written to `logs/mylog.txt`, and rotated files use the same base with numeric suffixes (e.g., `logs/mylog.txt.1`, `logs/mylog.txt.2`, ...).
Actual behavior: spdlog appends `.txt` again, producing `logs/mylog.txt.txt` (and corresponding rotated variants).

This should be fixed so that file-based sinks and factory helpers (including `spdlog::create<spdlog::sinks::simple_file_sink_mt>(...)`, `spdlog::rotating_logger_mt(...)`, and `spdlog::daily_logger_mt(...)`) do not hardcode a `.txt` suffix onto the provided filename/base name. The provided string must be treated as the full intended file path. Rotation and daily naming should still work correctly by appending their usual suffixes to that provided path (e.g., `.1` for rotating, timestamp/date segments for daily) without introducing an extra `.txt` extension.

After the change, passing a filename with no extension (e.g., `logs/rotating_log`) should continue to create and write to exactly that path (`logs/rotating_log`), and passing a filename with an extension (e.g., `logs/rotating_log.txt`) should write to exactly that path (`logs/rotating_log.txt`) without modification other than rotation/daily suffixing rules.
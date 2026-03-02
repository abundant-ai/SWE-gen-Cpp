When a test case uses `CHECKED_ELSE(...)` and then throws an uncaught exception, Catch2 can incorrectly suppress/misclassify the exception and report the test case as passing in some situations.

Reproducible example:
```cpp
#include <catch2/catch_test_macros.hpp>
#include <exception>

TEST_CASE("Testing") {
    CHECKED_ELSE(true) {}
    throw std::runtime_error("it is an error");
}
```

Expected behavior: The uncaught exception must be reported as a test failure, and the test run must count the test case as failed consistently across reporters (e.g., console and `-r xml`).

Actual behavior:
- After `CHECKED_ELSE(true) {}`, running with the XML reporter (`-r xml`) can mark the test case as successful (`success="true"`) and count it as a success even though an uncaught exception was thrown.
- After `CHECKED_ELSE(false) {}`, the uncaught exception can be suppressed and treated as passing in both console and XML output.

The bug is caused by assertion-related state not being fully reset after the `CHECKED_ELSE` handling, so later exception handling uses stale assertion disposition/state and incorrectly treats the exception as non-failing.

Fix this so that after `CHECKED_ELSE(...)` has executed, subsequent uncaught exceptions are never swallowed and always fail the test case. In particular, any internal “last assertion info” / result-disposition state used when generating the reaction to an exception must be restored to normal so that exception handling does not inherit a prior `CHECKED_ELSE` disposition.

After the fix, both of these scenarios must fail the test case and report the exception message (e.g., `it is an error`) across reporters:
1) `CHECKED_ELSE(true) {}` followed by throwing `std::runtime_error`.
2) `CHECKED_ELSE(false) {}` followed by throwing `std::runtime_error`.
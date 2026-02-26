When Catch2-based test executables are run under Bazel, Bazel sets the `XML_OUTPUT_FILE` environment variable to tell the test binary where to write JUnit XML results. Currently, running a Catch2 test binary with `XML_OUTPUT_FILE` set does not reliably produce a JUnit report at the given path without explicit reporter configuration, so Bazel cannot automatically collect test results.

Update Catch2 so that, when the `XML_OUTPUT_FILE` environment variable is present (and Bazel support is enabled via `CATCH_CONFIG_BAZEL_SUPPORT`), the framework automatically enables a JUnit reporter that writes to the exact file path specified by `XML_OUTPUT_FILE`.

This Bazel integration must not disable or replace the normal default console reporter output. In other words, even with `XML_OUTPUT_FILE` set, the test run should still print the standard human-readable console output including the final summary line in the form `test cases: <total> | <passed> passed | <failed> failed`.

Expected behavior when executing a Catch2 test binary with the environment variable set:

- A valid JUnit XML file is created at the path specified by `XML_OUTPUT_FILE`.
- The XML contains a `<testsuite>` element whose `name` matches the test executable’s file name (basename).
- The number of `<testcase>` elements equals the number of executed test cases.
- The number of `<failure>` elements equals the number of failed test cases.
- The process exit code should still reflect test success/failure normally (e.g., failing assertions should still cause a non-zero exit code), but the XML must be produced even when tests fail.

Actual behavior to fix: setting `XML_OUTPUT_FILE` does not result in the expected JUnit output file being generated/filled correctly, and/or enabling the XML output interferes with the default console reporting, making Bazel integration incomplete.
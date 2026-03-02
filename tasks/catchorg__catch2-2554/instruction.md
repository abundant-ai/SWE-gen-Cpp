When running Catch2 with the compact reporter, overall run totals are misleading for test cases tagged with `[!shouldfail]`.

Reproduction example:
```cpp
bool thisThrows() {
    throw std::runtime_error("Boom");
}

TEST_CASE("#748 - captures with unexpected exceptions", "[!shouldfail]") {
    int answer = 42;
    CAPTURE(answer);

    SECTION("outside assertions") {
        thisThrows();
    }
    SECTION("inside REQUIRE_NOTHROW") {
        REQUIRE_NOTHROW(thisThrows());
    }
    SECTION("inside REQUIRE_THROWS") {
        REQUIRE_THROWS(thisThrows());
    }
}
```

Current behavior (compact reporter): the final summary prints something like

```
Passed all 0 test cases with 1 assertion.
```

This is surprising/misleading because the run did execute a test case and multiple assertions, and the failures were expected due to `[!shouldfail]`.

Expected behavior: the compact reporter’s totals summary should include counts for outcomes that are “failed but ok” (i.e., failures that were expected due to `[!shouldfail]`), similar in meaning to the console reporter’s summary. For the example above, the summary should clearly communicate that:

- There was 1 test case and it “failed as expected”
- There were 3 assertions total, with 1 passed and 2 “failed as expected”

The compact reporter does not have to match the console reporter’s exact formatting character-for-character, but it must report the same information: total test cases/assertions, and explicit inclusion of the `failedButOk` counts for both test cases and assertions, rather than collapsing them into a confusing “Passed all 0 test cases …” message.

After the fix, running with the compact reporter on `[!shouldfail]` tests should produce a totals summary that reflects expected-failure outcomes instead of implying that nothing ran or that everything passed normally.
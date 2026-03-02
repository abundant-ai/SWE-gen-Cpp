When running Catch2 with randomized test ordering, test cases are hashed to create a subset-stable random order. Catch2 recently relaxed the “unique test case” criteria to allow multiple test cases that share the same name as long as they differ by tags and/or by the class name (for test cases associated with a type). However, the hashing used for randomized ordering still only considers the test case name, which makes hash collisions far more likely and guarantees collisions for intentionally duplicated names.

The randomized ordering should use a hash that reflects the full identity of a test case under the new uniqueness rules. Specifically, hashing a `Catch::TestCaseInfo` must incorporate all of the following:
- the test case’s class name (if any),
- the test case’s name,
- the test case’s tags string.

Add/implement a dedicated `Catch::TestCaseInfoHasher` callable object that can be constructed with an explicit seed and invoked as `hasher(testCaseInfo)` to return the hash value. The hasher must behave deterministically for the same seed and input.

Expected behavior:
- Two `Catch::TestCaseInfo` objects with equal class name, equal name, and equal tags must produce equal hashes when hashed with the same `Catch::TestCaseInfoHasher` instance (same seed).
- If class name and name are equal but tags differ, the hashes must differ (for the same seed).
- If class name and tags are equal but name differs, the hashes must differ (for the same seed).
- If name and tags are equal but class name differs, the hashes must differ (for the same seed).
- If two hashers are constructed with different seeds, hashing the same `Catch::TestCaseInfo` should produce different hash values.

Finally, update the randomized test ordering logic (used when `TestRunOrder::Randomized` is selected) so that it uses this new `Catch::TestCaseInfoHasher` rather than hashing only the name. This should reduce/avoid collisions for distinct test cases that are considered unique under the updated uniqueness criteria, and preserve subset-stable ordering properties.
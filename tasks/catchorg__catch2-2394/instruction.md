When `TestRunOrder::Randomized` is used, Catch2 computes a per-test hash to produce a subset-stable random ordering. After recent changes that allow multiple test cases to share the same display name (as long as they differ by tags, or by the class name for type-based tests), the hashing used for randomized ordering is no longer consistent with what Catch2 considers a “unique test case”.

Currently, the random-order hash only considers the test case name. This means that if two test cases have the same name but different tags, or the same name and tags but different class name, they will produce identical hashes. As a result, hash collisions become common (and even guaranteed for same-named test cases), which undermines randomized ordering by forcing frequent tie-breaking and reducing the effectiveness/quality of the randomization.

Fix the hashing used for randomized test ordering so that it incorporates all parts that define test case identity:
- the test case’s class name (for method/template-based test cases that “hang off” a type)
- the test case’s name
- the test case’s tags

Expose this logic as a dedicated callable hasher type named `Catch::TestCaseInfoHasher` that can be constructed with an explicit seed, and invoked like `hasher(testCaseInfo)` to return a hash value.

Expected behavior requirements:
- Two `Catch::TestCaseInfo` objects with equal class name, equal name, and equal tags must produce equal hashes when hashed with the same `TestCaseInfoHasher` seed.
- If any one of class name, name, or tags differ, the resulting hashes must differ (for the same hasher seed) in the scenarios above (same name different tags; same tags different name; same name+tags different class name).
- Two `TestCaseInfoHasher` instances constructed with different seeds must produce different hashes for the same `TestCaseInfo`.
- When `TestRunOrder::Randomized` is active, the sorting/precomputation of per-test hashes used by `getAllTestsSorted()` must use this updated hashing so that tests considered distinct under the “unique test case” rules are far less likely to collide solely due to sharing a name.
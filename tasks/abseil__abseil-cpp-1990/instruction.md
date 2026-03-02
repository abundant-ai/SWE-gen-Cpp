`absl::linked_hash_set` and `absl::linked_hash_map` do not correctly handle self-move assignment (e.g. `x = std::move(x)`), which can leave the container in an invalid state. After a self-move, operations like `contains()` and `find()` may fail (e.g. elements that were present become unfindable) and iterators returned by `find()` may not be reachable by iterating from `begin()` to `end()`. This indicates internal bookkeeping is corrupted.

Reproduction examples:

```cpp
absl::linked_hash_set<int> s = {1, 2, 3};
s = std::move(s);
// Should still behave as a valid container holding the same elements.
EXPECT_TRUE(s.contains(2));
auto it = s.find(2);
EXPECT_NE(it, s.end());
```

```cpp
absl::linked_hash_map<int, int> m = {{1, 10}, {2, 20}};
m = std::move(m);
EXPECT_TRUE(m.contains(2));
auto it = m.find(2);
EXPECT_NE(it, m.end());
```

Expected behavior: self-move assignment must be a safe no-op (or otherwise leave the container in a valid state) such that the container remains usable, retains its elements, and `find()` returns an iterator that is part of the container’s iteration sequence.

Actual behavior: performing `operator=(linked_hash_{set|map}&&)` with the same object can invalidate internal structure, causing lookups/iteration consistency checks to fail.

Fix `absl::linked_hash_set` and `absl::linked_hash_map` move-assignment behavior so that `x = std::move(x)` preserves container validity and lookup/iteration consistency for both sets and maps across common key/value types.
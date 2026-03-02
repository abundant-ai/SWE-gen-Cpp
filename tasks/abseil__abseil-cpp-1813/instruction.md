absl::{flat,node}_hash_{set,map} allow callers to provide an initial size (via sized constructors) or request a size change (via reserve() and rehash()) with an arbitrarily large size_t argument. Today these APIs do not enforce an upper bound, so extremely large values can overflow internal size computations for the backing store (e.g., when converting requested element counts into bucket/control-array sizes). After this overflow, the container may allocate a too-small backing store and later perform out-of-bounds memory access during inserts/lookups/rehashing.

The containers should have a well-defined maximum number of elements they can safely store, and max_size() should reflect that limit (i.e., the maximum item count that can be stored without overflowing internal capacity/allocation calculations).

Fix the overflow vulnerability by doing two things:

1. Correct max_size(): Update the implementation so that calling max_size() on absl::flat_hash_set, absl::flat_hash_map, absl::node_hash_set, and absl::node_hash_map returns the true maximum number of items that can be stored, not a value that could exceed what internal capacity/allocation math can represent.

2. Validate size arguments: In the sized constructors, reserve(size_type n), and rehash(size_type n) for these containers, validate the provided argument against the container’s supported maximum. If the argument is invalid (too large to be represented safely, or would require internal backing-store sizes that overflow), the program must abort rather than proceeding with an overflowed allocation.

Reproduction example (should no longer lead to overflow/OOB; instead it should terminate the program):

```cpp
absl::flat_hash_set<int> s;
s.reserve(std::numeric_limits<size_t>::max());
```

Similarly, constructing with an enormous initial bucket/size hint or calling rehash() with an enormous value must also abort.

Expected behavior: max_size() returns an upper bound that is consistent with what reserve()/rehash()/constructors accept; any request larger than this limit is rejected by aborting the process. Actual behavior before the fix: very large values can overflow internal computations and may later cause out-of-bounds memory access.
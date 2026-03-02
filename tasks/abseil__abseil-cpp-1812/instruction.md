absl::flat_hash_set, absl::flat_hash_map, absl::node_hash_set, and absl::node_hash_map do not correctly bound-check size-related inputs in their sized constructors and in reserve() and rehash(). A caller can pass an extremely large size (or bucket count) that causes an integer overflow while computing the backing storage size/capacity. After the overflow, the container may allocate an undersized backing store and later operations can read/write out of bounds.

This needs to be fixed by enforcing a correct upper bound on how many elements the container can ever hold and by validating all size arguments that can trigger allocation/resizing.

max_size() currently does not accurately reflect the maximum number of items that can be stored safely. Update max_size() so it returns the true maximum element count supported by the implementation (i.e., the largest size for which internal capacity/backing-store computations remain well-defined without overflow).

Then, ensure the following APIs reject invalidly large arguments:
- The “sized” constructors of the hash containers (constructing with an initial bucket/element count)
- reserve(size_type n)
- rehash(size_type n)

When any of these are called with an argument greater than what the container can support (as determined by max_size() and any related capacity constraints), the program must fail fast by aborting rather than attempting to proceed with an overflowed allocation.

Expected behavior: for all four container types, calling reserve(), rehash(), or a sized constructor with a value larger than the supported maximum must deterministically abort the program; calling them with values up to the maximum must not overflow internal size computations and must behave normally.

Actual behavior: very large values can overflow internal arithmetic used to compute storage size/capacity, allowing subsequent container access to touch memory out of bounds.
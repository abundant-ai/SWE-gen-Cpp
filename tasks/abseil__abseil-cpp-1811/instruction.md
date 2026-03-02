absl::{flat,node}_hash_{set,map} can be constructed or resized with extremely large size arguments (via sized constructors, reserve(), or rehash()) without any upper-bound validation. For sufficiently large values, internal calculations for the backing store size can overflow size_t, leading to allocating an undersized table. Subsequent operations may then read/write out of bounds.

The containers should define a correct upper bound for how many elements can be stored and reject (terminate) requests that exceed that bound.

Update the container’s max_size() so it returns the maximum number of items that can be safely stored given the implementation’s backing-store sizing rules (including control bytes / metadata overhead and any load-factor or growth policy constraints). Then, validate all user-provided size arguments in these APIs:

- sized constructors that accept an initial bucket/element count
- reserve(size_type n)
- rehash(size_type n)

When a caller passes a size greater than max_size() (or otherwise invalid such that computing the required backing-store size would overflow), the program must abort (fail fast) rather than attempting to proceed.

Expected behavior:
- For any n where n > max_size(), calling reserve(n) or rehash(n) must abort the program.
- For any sized constructor given an invalid n (as above), construction must abort.
- For valid sizes (n <= max_size()), behavior should remain unchanged and no spurious aborts should occur.

This change is specifically to prevent integer overflow in backing-store sizing computations and the resulting out-of-bounds memory access on later container operations.
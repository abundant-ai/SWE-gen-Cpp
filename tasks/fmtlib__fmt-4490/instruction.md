`fmt::basic_memory_buffer` is not movable/assignable when used with non-propagating allocators such as `std::pmr::polymorphic_allocator`. In particular, `std::allocator_traits<std::pmr::polymorphic_allocator<T>>::propagate_on_container_move_assignment` is `false`, and `std::pmr::polymorphic_allocator` has its move assignment operator deleted. However, `basic_memory_buffer::operator=(basic_memory_buffer&& other)` currently performs allocator move-assignment unconditionally, which makes common code fail to compile.

A minimal example that should compile but currently does not:

```cpp
std::pmr::unsynchronized_pool_resource r1;
using pmr_memory_buffer = fmt::basic_memory_buffer<char, 10, std::pmr::polymorphic_allocator<char>>;

pmr_memory_buffer b1{&r1};
pmr_memory_buffer b2{&r1};

b2 = std::move(b1);  // should compile
```

This also blocks use in standard containers that require moveability, e.g. inserting a `basic_memory_buffer` with a `std::pmr::polymorphic_allocator` into a `std::pmr::vector`.

`basic_memory_buffer` move behavior needs to become allocator-aware:

When moving/assigning from another buffer, the implementation must respect `std::allocator_traits<Allocator>::propagate_on_container_move_assignment`.

- If `propagate_on_container_move_assignment` is `true`, move assignment should propagate the allocator from `other` as part of the move (current behavior is acceptable).
- If `propagate_on_container_move_assignment` is `false`, move assignment must not attempt to move-assign the allocator.
  - If the allocators compare equal, the buffer contents may be moved efficiently.
  - If the allocators differ, the destination buffer must end up with the same allocator it already had, and the characters from `other` must still be transferred correctly (i.e., perform a copy/clone of the content rather than “ripping the guts” in a way that would require allocator propagation).

As part of this, allocator comparison must be well-defined for the allocator types used with `basic_memory_buffer` in this project’s codebase (including the internal/testing allocator wrappers), so that the implementation can decide whether allocators are equal when propagation is disabled.

Expected results:
- The above `std::pmr::polymorphic_allocator` move-assignment example compiles.
- Move construction and move assignment of `basic_memory_buffer` follow standard allocator-aware container semantics: allocator propagation only when enabled; otherwise allocator remains unchanged and content transfer behaves correctly for both equal and unequal allocators.
- Existing behaviors that assumed “move always transfers allocator” or “move always leaves the source empty by stealing its storage” must be updated to reflect the correct semantics for non-propagating allocators, without breaking behavior for propagating allocators.
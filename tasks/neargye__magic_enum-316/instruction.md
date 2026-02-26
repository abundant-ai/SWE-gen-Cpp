Some builds fail (or behave inconsistently across compilers/stdlibs) because the library declares a full specialization/extension of the standard library function template `std::get` for magic_enum container types. Extending `std` this way is undefined behavior in C++, and depending on platform/toolchain it can lead to compile errors or other unexpected results.

The library currently enables tuple-like access to its container types via `std::get<Index>(value)` and/or `std::get<Type>(value)`. This must be changed so that no declaration or specialization of `std::get` is provided by the library.

Provide an alternative, supported API by moving the `get` customization point into the library namespace: users should use `magic_enum::containers::get<Index>(value)` (and any type-based overloads that were previously supported) to access elements. Any tuple-like integration the library provides (e.g., structured bindings / `std::tuple_size` / `std::tuple_element` support if present) must continue to work without relying on adding `get` into `std`.

After the change:
- Code that previously relied on `std::get` for magic_enum container types should be updated to call `magic_enum::containers::get` instead.
- The project must compile cleanly on standard-conforming toolchains without defining or specializing `std::get`.
- Element access via `magic_enum::containers::get` should preserve the previous behavior (including `constexpr`/`noexcept` properties as applicable) for the supported magic_enum container types.
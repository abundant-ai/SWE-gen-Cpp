When installing yaml-cpp and consuming it via CMake using `find_package(yaml-cpp CONFIG REQUIRED)`, the generated `yaml-cpp-config.cmake` currently provides incorrect or non-relocatable values, which breaks package managers that relocate CMake config files (notably vcpkg) and can also mislead normal consumers.

There are three user-visible problems in the generated config:

1) `YAML_CPP_SHARED_LIBS_BUILT` is not a real boolean.
The config sets `YAML_CPP_SHARED_LIBS_BUILT` using a path-style substitution, which expands to something like `${PACKAGE_PREFIX_DIR}/<value>`. In CMake, this is effectively always a non-empty string and therefore truthy, even when yaml-cpp was built as a static library. As a result, consumers cannot reliably detect whether the installed library is shared or static.

Expected behavior: after `find_package(yaml-cpp CONFIG REQUIRED)`, `YAML_CPP_SHARED_LIBS_BUILT` must accurately reflect how yaml-cpp itself was built (true for shared builds, false for static builds). Consumers should be able to compare it to the actual imported target type without contradictions.

2) The config is not relocatable because it includes the exported targets file via a prefix-based path variable.
The config loads `yaml-cpp-targets.cmake` using a path derived from a substituted install prefix variable. Package managers like vcpkg move CMake config files to a different directory after installation (e.g., to `share/<package>`), and patch prefix variables (`PACKAGE_PREFIX_DIR`, `_IMPORT_PREFIX`). If the config relies on a prefix-derived path variable to include the targets file, this relocation can cause the include to point at the wrong location and fail.

Expected behavior: `find_package(yaml-cpp CONFIG REQUIRED)` should succeed even if the installed CMake config files are relocated together, as long as `yaml-cpp-config.cmake` and `yaml-cpp-targets.cmake` remain in the same directory. The config should load the targets file from its own directory (relative to the config file) rather than from a separately substituted prefix path.

3) `YAML_CPP_LIBRARIES` points to the wrong thing.
The config sets `YAML_CPP_LIBRARIES` to `yaml-cpp` (without namespace), but consumers are expected to link against the imported target `yaml-cpp::yaml-cpp`. Linking with `${YAML_CPP_LIBRARIES}` therefore does not work reliably.

Expected behavior: after `find_package(yaml-cpp CONFIG REQUIRED)`, `YAML_CPP_LIBRARIES` should be set so that `target_link_libraries(app PRIVATE ${YAML_CPP_LIBRARIES})` correctly links against yaml-cpp, and the canonical imported target `yaml-cpp::yaml-cpp` must be available.

Additionally, provide a CMake option to control where the package config files are installed:

- Add an option named `YAML_CPP_INSTALL_CMAKEDIR` that allows choosing the install directory for the generated CMake package config and targets files. This is needed by package managers that require a specific convention for config placement.

A minimal consumer scenario that must work:

```cmake
find_package(yaml-cpp CONFIG REQUIRED)
get_target_property(LIBRARY_TYPE yaml-cpp::yaml-cpp TYPE)

# YAML_CPP_SHARED_LIBS_BUILT must match LIBRARY_TYPE

add_executable(main main.cpp)
target_link_libraries(main PRIVATE ${YAML_CPP_LIBRARIES})
```

Currently, consumers can see contradictions like a static `yaml-cpp::yaml-cpp` target while `YAML_CPP_SHARED_LIBS_BUILT` still evaluates true, and relocation can break loading of `yaml-cpp-targets.cmake`. Fix the generated config so these behaviors are correct and robust.
When a project installs yaml-cpp and downstream consumers use `find_package(yaml-cpp CONFIG REQUIRED)`, the generated CMake package configuration is currently incorrect in several ways that break or mislead consumers, especially in package-manager environments that relocate installed CMake config files (e.g., moving them under `share/<pkg>` and patching prefix variables).

1) `YAML_CPP_SHARED_LIBS_BUILT` is set using a path-style substitution so it expands to something like `${PACKAGE_PREFIX_DIR}/<value>`. In CMake this evaluates as a non-empty string and is effectively always true, so consumers cannot reliably detect whether yaml-cpp was built as a shared or static library. As a result, a consumer that checks the imported target type (e.g., `get_target_property(... TYPE)`) can find that `YAML_CPP_SHARED_LIBS_BUILT` contradicts the actual library type.

`YAML_CPP_SHARED_LIBS_BUILT` must instead evaluate to a real boolean reflecting how yaml-cpp was built/installed, so consumers can do logic like:

```cmake
find_package(yaml-cpp CONFIG REQUIRED)
get_target_property(LIBRARY_TYPE yaml-cpp::yaml-cpp TYPE)
# If LIBRARY_TYPE is SHARED_LIBRARY then YAML_CPP_SHARED_LIBS_BUILT must be true,
# otherwise it must be false.
```

2) The package config includes `yaml-cpp-targets.cmake` via a path that depends on an install-time directory variable rather than being relative to the config file itself. This breaks in environments where the config directory is relocated after install, because the computed path no longer points at the targets file. The config must load the targets file in a way that continues to work after relocation, assuming the config and targets files are installed side-by-side.

3) `YAML_CPP_LIBRARIES` is currently set to `yaml-cpp` (without namespace), but the consumer-visible imported target is `yaml-cpp::yaml-cpp`. Consumers that do `target_link_libraries(... PRIVATE ${YAML_CPP_LIBRARIES})` should successfully link without needing to guess the correct target name. `YAML_CPP_LIBRARIES` should therefore resolve to the namespaced target that `find_package` actually provides.

4) There should be an install-time option to control where the CMake package config files are installed (for example, package managers may require configs under a specific directory such as `share/<pkg>`). Add a CMake option (e.g., `YAML_CPP_INSTALL_CMAKEDIR`) that allows overriding the install destination for the generated config/targets files while keeping the config functional.

After these changes, a minimal consumer project should be able to `find_package(yaml-cpp CONFIG REQUIRED)`, observe a correct `YAML_CPP_SHARED_LIBS_BUILT` boolean consistent with `yaml-cpp::yaml-cpp`’s imported target type, and link successfully using `target_link_libraries(... PRIVATE ${YAML_CPP_LIBRARIES})`, even if the installed CMake config directory is relocated as long as the config and targets files remain together.
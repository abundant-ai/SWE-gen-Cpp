pugixml’s std::string_view API support currently requires users to explicitly enable it via a build define (PUGIXML_STRING_VIEW) and ensure the library is compiled as C++17. This creates unnecessary friction for users on compilers that already support C++17, and it also leads to inconsistent behavior across build systems: some builds can support std::string_view but don’t unless manually configured, while other configurations (notably MSVC defaults) may compile without C++17 unless explicitly requested.

Change the default behavior so that std::string_view support is automatically enabled whenever the compiler supports C++17 (and the library is being built in a mode compatible with it), without requiring users to define PUGIXML_STRING_VIEW.

At the same time, update the project’s build configurations so that C++17 is enabled automatically in common cases where it is safe and expected, but without forcing C++17 requirements onto downstream/dependent projects:

- When building via CMake, if the user has not explicitly set a C++ standard (e.g., no explicit CMAKE_CXX_STANDARD is provided), the build should attempt to use C++17 when the compiler supports it, but should allow transparent downgrade when C++17 is not available. This should not make dependent targets require C++17.
- When building via Visual Studio project files for modern Visual Studio versions that support it, the projects should compile with /std:c++17 so that std::string_view support is available out of the box.

After these changes, users compiling pugixml with a C++17-capable toolchain should be able to use the std::string_view-based overloads/APIs without any special preprocessor defines, while users on older compilers should still be able to build successfully (with std::string_view APIs not available).
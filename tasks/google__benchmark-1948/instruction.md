Building the library in C++14 mode fails even though the documentation/expected minimum standard indicates C++14 support. With Clang (e.g., 16.x) using `-std=c++14`, compilation errors occur because the code uses C++17-only types such as `std::string_view`, for example:

```
error: no type named 'string_view' in namespace 'std'
  CheckHandler(std::string_view check, std::string_view file,
               ~~~~~^
```

The project should have a consistent, enforced minimum C++ standard across its public headers and build configurations. Either the code must not require C++17 when the project claims C++14 compatibility, or—if C++17 is now required—the build system and compilation checks must be updated so that building and testing always use C++17 and fail early with a clear diagnostic when compiled with an older standard.

After the fix, building the library and its tests with the supported standard must succeed, and attempts to compile with an older standard (such as C++14) must be rejected in a predictable way (e.g., via a compile-time error that indicates the wrong C++ standard is being used), rather than failing later with missing-type errors like `std::string_view` not being found.
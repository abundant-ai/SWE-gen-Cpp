Compiling a project that includes fmt’s public header fails with Intel C++ compilers in configurations where user-defined literals (UDLs) are not actually supported or are supported only under specific language modes.

Two failure modes have been reported:

1) With Intel C++ 2019 beta in C++14 mode, including the header triggers a hard compile error around the `_format` user-defined literal template, e.g.:

```
error: a literal operator template must have a template parameter list equivalent to "<char ...>"
FMT_CONSTEXPR internal::udl_formatter<Char, CHARS...> operator""_format() {
                                                    ^
```

2) With Intel C++ compiler version 14 in C++11 mode, the library incorrectly enables UDL support, and including the header fails with an error like:

```
error: expected an operator
operator"" _format(const char *s, std::size_t) { return {s}; }
```

The root problem is that the compile-time macro used to control whether fmt declares its user-defined literals (`FMT_USE_USER_DEFINED_LITERALS`) is not reliably detecting UDL support on Intel compilers. In particular, when using Intel on Linux/macOS (icpc/icc) or Windows (icl), support can depend both on the Intel compiler version and on the host toolchain / selected standard mode, and the current detection can mistakenly enable UDLs.

Update the feature detection so that `FMT_USE_USER_DEFINED_LITERALS` is only enabled when the active compilation environment truly supports the required UDL form, including on Intel compilers identified by `__ICC` (Linux/macOS) and `__ICL` (Windows). The header must not declare the `_format` literal operators (including template-based forms) when the compiler cannot compile them.

Additionally, ensure that the header’s `FMT_USE_USER_DEFINED_LITERALS` value matches the build-system’s determination of whether user-defined literals are supported for the current compiler and selected C++ standard flags. A configuration that the build system considers to not support UDLs must not result in `FMT_USE_USER_DEFINED_LITERALS` being set to 1 in the header, and vice versa.

After the fix, the following should hold:
- Including the fmt header compiles cleanly with Intel C++ 14 in C++11 mode (UDLs must be disabled there).
- Including the fmt header compiles cleanly with Intel C++ 2019-era compilers in C++14 mode without triggering invalid literal-operator-template declarations.
- `FMT_USE_USER_DEFINED_LITERALS` consistently reflects actual compiler support across GCC/Clang/MSVC/Intel and does not depend on mis-detected host-compiler capabilities.
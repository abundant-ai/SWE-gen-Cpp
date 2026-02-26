Building the library on Windows fails due to incorrect DLL import/export annotations on several functions and one internal global. Some functions are declared with the correct dllexport/dllimport macro but their out-of-line definitions are missing the same annotation (or vice versa). On MSVC, this can lead to build or link errors such as inconsistent DLL linkage (for example, errors like “inconsistent dll linkage”/C4273) or unresolved external symbols when a consumer links against the built DLL.

The codebase uses a visibility macro (commonly expressed as something like BENCHMARK_EXPORT) to control symbol export/import on Windows. That macro must be applied consistently on Windows to any function intended to be part of the DLL interface: the macro needs to appear not only on the function declaration but also on the corresponding function definition when the definition is out-of-line.

Additionally, there is a private/internal global field named global_context that was incorrectly marked with a DLL import/export attribute even though it is not part of the public exported interface. This causes Windows builds to fail or behave inconsistently because the symbol is treated as exported/imported without being exported in a consistent way.

Fix the Windows build by ensuring:

1) Any exported/imported API function has consistent dllexport/dllimport annotation on both its declaration and its definition.

2) The internal/private global_context symbol is not annotated as imported/exported (it should not be treated as part of the DLL interface).

After the change, the project should compile and link successfully on Windows (MSVC) in DLL configurations, and existing behavior of internal helpers such as AddRange (used to generate integer ranges for benchmark argument registration) must remain unchanged.
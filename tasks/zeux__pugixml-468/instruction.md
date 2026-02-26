NuGet consumers using Visual Studio 2022 with MSVC platform toolset v143 cannot link against the shipped pugixml NuGet package because the package does not include libraries under the expected v143 directory layout.

Repro: In Visual Studio 2022, select platform toolset v143 and install the pugixml NuGet package (including configurations like Dynamic CRT). Build a project that links pugixml from the package.

Actual behavior: the link step fails because the expected library path does not exist in the installed package, e.g. it looks for:

packages\pugixml.1.11.0\build\native\lib\x64\v143\dynamic\Debug\pugixml.lib

but only v142 (VS2019) libraries are present under the corresponding lib directory.

Expected behavior: When building with toolset v143 (VS2022), NuGet package resolution should find a matching pugixml binary for the selected architecture (x86/x64), toolset version (v143), CRT choice (dynamic/static), and configuration (Debug/Release), so linking succeeds without manual path fixes.

Update the build/packaging logic so that the NuGet package includes the correct MSVC v143 library outputs and exposes them via the same conventions used for earlier toolsets (so that VS2022 projects automatically resolve to v143 binaries). Also ensure the Windows build/CI scripts recognize Visual Studio 2022 (VS2022 developer environment) so the v143 build is exercised alongside existing VS versions.
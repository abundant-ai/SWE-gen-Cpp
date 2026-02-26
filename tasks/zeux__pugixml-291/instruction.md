When consuming pugixml via the published NuGet package in a Visual Studio 2019 toolset (v142) project, linking fails because the package does not contain libraries under the expected v142 folder layout. After upgrading a solution to PlatformToolset v142, builds report an error like:

cannot open input file '...\packages\pugixml.1.9.0\build\native\lib\x64\v142\dynamic\Release\pugixml.lib'

This happens because the NuGet package only provides binaries for the older v141 toolset directories, so MSBuild/NuGet integration resolves a v142 path that does not exist.

Update the NuGet creation/build process so that, in addition to existing toolsets, it produces and packages pugixml binaries compatible with Visual Studio 2019 (v142) for both x86 and x64, and for the package variants that are expected (e.g., dynamic/static, Debug/Release) so that a v142 consumer can restore the package and successfully link without needing to retarget or manually copy libraries. The Visual Studio project generation/build inputs used for packaging must be VS2019-compliant so the build can run in a VS2019 environment and emit the v142 artifact directory structure that NuGet consumers expect.
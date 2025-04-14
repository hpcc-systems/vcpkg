# vcpkg Copilot Instructions

This is a C/C++ package manager (vcpkg) maintained by Microsoft. Focus on these architectural patterns and workflows when working with this codebase.

## Resources

- **Official Documentation**: https://learn.microsoft.com/en-us/vcpkg/
- **Official Repository**: https://github.com/microsoft/vcpkg

## Architecture Overview

**Package Manager Structure**: vcpkg follows a port-based architecture where each C/C++ library is a "port" with:
- `ports/[package-name]/portfile.cmake` - Build instructions using vcpkg CMake functions  
- `ports/[package-name]/vcpkg.json` - Package metadata (name, version, dependencies, features)
- `versions/[first-letter]/[package-name].json` - Version history tracking
- `versions/baseline.json` - Default version for all ports

**Core Build System**: Built on CMake with custom functions in `scripts/cmake/`:
- `vcpkg_from_github()` - Download sources from GitHub
- `vcpkg_cmake_configure()` - Configure CMake builds
- `vcpkg_cmake_install()` - Install built packages
- `vcpkg_fixup_cmake_targets()` - Fix CMake config files for consumption

**Triplet System**: Platform specifications in `triplets/` define:
- Target architecture (`VCPKG_TARGET_ARCHITECTURE`)  
- Library linkage (`VCPKG_LIBRARY_LINKAGE` - static/dynamic)
- CRT linkage (`VCPKG_CRT_LINKAGE` - static/dynamic)
- Example: `x64-linux.cmake`, `arm64-windows.cmake`

## Key Development Workflows  

**Bootstrap the Tool**: `./bootstrap-vcpkg.sh` builds the vcpkg binary from source
- Uses `scripts/bootstrap.sh` with compiler detection
- Creates the main `vcpkg` executable

**Package Installation**: 
```bash
./vcpkg install [package]:[triplet]  # Classic mode
./vcpkg install --triplet [triplet]  # Manifest mode (reads vcpkg.json)
```

**Port Development**:
1. Create `ports/[name]/portfile.cmake` with build logic
2. Add `ports/[name]/vcpkg.json` with metadata  
3. Test with `./vcpkg install [name] --triplet [triplet]`
4. Update `versions/` files for version tracking

**CI/Testing**: 
- `scripts/ci.baseline.txt` - Expected build states per triplet
- `buildtrees/[package]/[triplet]-[rel|dbg]/` - Build artifacts and logs
- Use `--debug` flag for verbose output during development

## Project-Specific Patterns

**CMake Function Style**: All port builds use vcpkg-specific CMake functions:
```cmake
vcpkg_from_github(OUT_SOURCE_PATH SOURCE_PATH REPO org/repo REF v1.0.0 SHA512 ...)
vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}" OPTIONS -DBUILD_TESTS=OFF)
vcpkg_cmake_install()
```

**Patch Management**: Apply fixes via `PATCHES` parameter:
```cmake
vcpkg_from_github(... PATCHES fix-cmake.patch fix-headers.patch)
```

**Feature System**: Optional components defined in `vcpkg.json` features:
```json
"features": {
  "openssl": {"description": "SSL support", "dependencies": ["openssl"]}
}
```

**Cross-Platform Handling**: Use conditionals for platform differences:
```cmake  
if(VCPKG_TARGET_IS_WINDOWS)
    # Windows-specific logic
elseif(VCPKG_TARGET_IS_LINUX)  
    # Linux-specific logic
endif()
```

**Overlay System**: Custom ports/triplets in `overlays/` override built-in versions

## Critical Files for AI Understanding

- `scripts/ports.cmake` - Master include of all vcpkg functions
- `scripts/buildsystems/vcpkg.cmake` - CMake toolchain integration  
- `ports/[package]/portfile.cmake` - Package build logic (examine existing ones for patterns)
- `versions/baseline.json` - Version tracking (10k+ entries)
- `triplets/` - Platform configurations
- `buildtrees/` - Build outputs and logs for debugging

## Build System Integration

**Manifest Mode**: Projects include `vcpkg.json` for dependency management
**Classic Mode**: Global installation via command line
**CMake Integration**: Projects use vcpkg toolchain via `-DCMAKE_TOOLCHAIN_FILE=[vcpkg-root]/scripts/buildsystems/vcpkg.cmake`

When debugging build issues, check logs in `buildtrees/[package]/[triplet]-[rel|dbg]/` and use `--debug` for detailed output.

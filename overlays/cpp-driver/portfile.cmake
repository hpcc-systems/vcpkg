# Common Ambient Variables:
# CURRENT_BUILDTREES_DIR    = ${VCPKG_ROOT_DIR}\buildtrees\${PORT}
# CURRENT_PACKAGES_DIR      = ${VCPKG_ROOT_DIR}\packages\${PORT}_${TARGET_TRIPLET}
# CURRENT_PORT_DIR          = ${VCPKG_ROOT_DIR}\ports\${PORT}
# CURRENT_INSTALLED_DIR     = ${VCPKG_ROOT_DIR}\installed\${TRIPLET}
# DOWNLOADS                 = ${VCPKG_ROOT_DIR}\downloads
# PORT                      = current port name (zlib, etc)
# TARGET_TRIPLET            = current triplet (x86-windows, x64-windows-static, etc)
# VCPKG_CRT_LINKAGE         = C runtime linkage type (static, dynamic)
# VCPKG_LIBRARY_LINKAGE     = target library linkage type (static, dynamic)
# VCPKG_ROOT_DIR            = <C:\path\to\current\vcpkg>
# VCPKG_TARGET_ARCHITECTURE = target architecture (x64, x86, arm)
# VCPKG_TOOLCHAIN           = ON OFF
# TRIPLET_SYSTEM_ARCH       = arm x86 x64
# BUILD_ARCH                = "Win32" "x64" "ARM"
# MSBUILD_PLATFORM          = "Win32"/"x64"/${TRIPLET_SYSTEM_ARCH}
# DEBUG_CONFIG              = "Debug Static" "Debug Dll"
# RELEASE_CONFIG            = "Release Static"" "Release DLL"
# VCPKG_TARGET_IS_WINDOWS
# VCPKG_TARGET_IS_UWP
# VCPKG_TARGET_IS_LINUX
# VCPKG_TARGET_IS_OSX
# VCPKG_TARGET_IS_FREEBSD
# VCPKG_TARGET_IS_ANDROID
# VCPKG_TARGET_IS_MINGW
# VCPKG_TARGET_EXECUTABLE_SUFFIX
# VCPKG_TARGET_STATIC_LIBRARY_SUFFIX
# VCPKG_TARGET_SHARED_LIBRARY_SUFFIX
#
# See additional helpful variables in /docs/maintainers/vcpkg_common_definitions.md

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO datastax/cpp-driver
    REF 2.16.2
    SHA512 6dee9ceaafa1a86bacd54759931d6cf794c50cb2e0944a568b2e36f04f4151d816f7d041ef17d70b1d0133497ec25f8f975c166b4fc6f882df23d0725bb0e28a
    HEAD_REF master
)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/cmake/Dependencies.cmake DESTINATION ${SOURCE_PATH}/cmake)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    DISABLE_PARALLEL_CONFIGURE

    OPTIONS
        -DCASS_BUILD_SHARED=OFF
        -DCASS_BUILD_STATIC=ON
        -DCASS_INSTALL_HEADER_IN_SUBDIR=OFF
)

vcpkg_cmake_install()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${SOURCE_PATH}/LICENSE.txt" DESTINATION "${CURRENT_PACKAGES_DIR}/share/cpp-driver" RENAME copyright)

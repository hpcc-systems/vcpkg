include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO chromiumembedded/cef-project
    REF 8d5b06ed442dce2a5be21650d18167e74dbbad86
    SHA512 d61286d4b94d84d335952c9e18619d8253411979a501b25a8a080a2f4b77530ac0a893bbe289d759be71ddd3b0884186f7e270601d8dacc1ce86e7dc6d33976a
    HEAD_REF master
    PATCHES cef_builds_url.patch
)

file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
vcpkg_execute_required_process(
    COMMAND cmake "${SOURCE_PATH}" -A Win32 -DCEF_RUNTIME_LIBRARY_FLAG=/MDd
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
    LOGNAME configure-${TARGET_TRIPLET}-dbg
)
vcpkg_execute_required_process(
    COMMAND cmake --build . --target libcef_dll_wrapper --config Debug
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
    LOGNAME build-${TARGET_TRIPLET}-dbg
)

file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
vcpkg_execute_required_process(
    COMMAND cmake "${SOURCE_PATH}" -A Win32 -DCEF_RUNTIME_LIBRARY_FLAG=/MD
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
    LOGNAME configure-${TARGET_TRIPLET}-rel
)
vcpkg_execute_required_process(
    COMMAND cmake --build . --target libcef_dll_wrapper --config Release
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
    LOGNAME build-${TARGET_TRIPLET}-rel
)

file(GLOB CEF_SEARCH_PATHS "${SOURCE_PATH}/third_party/cef/*")
find_path(CEF_ROOT_DIR 
    NAMES include/cef_client.h
    PATHS ${CEF_SEARCH_PATHS}
)

file(INSTALL ${CEF_ROOT_DIR}/include DESTINATION ${CURRENT_PACKAGES_DIR}/include/cef-project)
#file(INSTALL ${CEF_ROOT_DIR}/Debug/libcef.lib DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
#file(INSTALL ${CEF_ROOT_DIR}/Release/libcef.lib DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
#file(INSTALL ${CEF_ROOT_DIR}/Debug/libcef.dll DESTINATION ${CURRENT_PACKAGES_DIR}/debug/bin)
#file(INSTALL ${CEF_ROOT_DIR}/Release/libcef.dll DESTINATION ${CURRENT_PACKAGES_DIR}/bin)
file(INSTALL ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/libcef_dll_wrapper/Debug/libcef_dll_wrapper.lib DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
file(INSTALL ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/libcef_dll_wrapper/Release/libcef_dll_wrapper.lib DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
file(INSTALL ${SOURCE_PATH}/LICENSE.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/cef-project RENAME copyright)

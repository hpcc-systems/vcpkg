vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO VisualText/nlp-engine
  REF v${VERSION}
  SHA512 d874bb29b405efbb5f988f4c5e08d9caa0afd1a2b7ec95a3d580095a89d703511b1a9deb9cf036e9b53e0416b307ec4b911bf5dafa2f6418faf36bb80effa40e
  HEAD_REF master
)

vcpkg_from_github(
  OUT_SOURCE_PATH ANALYZER_PATH
  REPO VisualText/analyzers
  REF v1.6.2
  SHA512 07479c8ba1f36c3a0bb035af7414e96ce1477ffaa8a276256fc3749d169c0bb99f9ac9ad5c9b5b0868d634644013c46643a90598dd465e4f16bbe82a47ac60fe
  HEAD_REF master
)

vcpkg_from_github(
  OUT_SOURCE_PATH PARSE_EN_US_PATH
  REPO VisualText/parse-en-us
  REF v1.1.1
  SHA512 1aa01c0befe82b8fe415576ae992b0b60fe51b816e93fd8f45da4c5ccacc3dc87c21373ba001cf0d0c503131b4b83346e86f1522795901bbceb07c63a52d6294
  HEAD_REF master
)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt DESTINATION ${SOURCE_PATH})
file(COPY "${ANALYZER_PATH}/." DESTINATION "${SOURCE_PATH}/analyzers" PATTERN "*.*")
file(COPY "${PARSE_EN_US_PATH}/." DESTINATION "${SOURCE_PATH}/analyzers/parse-en-us" PATTERN "*.*")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
)
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(PACKAGE_NAME "nlp-engine" CONFIG_PATH "share/cmake/nlp-engine")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

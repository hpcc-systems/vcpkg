set(VERSION 1.16.0)

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO hpcc-systems/nlp-engine
  REF 6205486cee6194fd345e89c7c10eb62645ef5b27
  SHA512 d5da079d88c4ac72280b7e1c49aef2bd57bb29220f6987f53a5493851373f0f2a00c70f1931e7a3af2e0c440e247606c815b0efbde6fe8c968f9d9aff090624c
  HEAD_REF master
)

vcpkg_from_github(
  OUT_SOURCE_PATH ANALYZER_PATH
  REPO VisualText/analyzers
  REF 4f788331088f5d9f182fa5c1a6a6d7c96033b867
  SHA512 31cf282729d978c11387b5db1e19f08cb39e7ca777573a0bf635fd69a8796f93c3c5cd36a46bbfd6a76fe4cd1927f2d0a025df6b3c598b114b046aec6651d77d
  HEAD_REF master
)

vcpkg_from_github(
  OUT_SOURCE_PATH PARSE_EN_US_PATH
  REPO VisualText/parse-en-us
  REF f3fa7967e4238ebf74d4252eef18ab3261fa2af9
  SHA512 b203b37445f1f68d7d6e349726b441851ac5439fa45c4766aabc563861971a0cb4f6cad64b5b939fe9cd32737d7dcc62ae41804115593560dad095633dcfb820
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

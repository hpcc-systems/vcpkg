set(VERSION 1.21.7)

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO VisualText/nlp-engine
  REF 97985e07a580bfcdc13bef492308a59b31faab09
  SHA512 520ea673b8942315af91fd4808841bdcaa5d5426763d4c9d32e3903fe4b602e66465cc337c8422377ae212b002c0f256af9d695da81290886dc44254e25b602c
  HEAD_REF master
)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt DESTINATION ${SOURCE_PATH})

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
)
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(PACKAGE_NAME "nlp-engine" CONFIG_PATH "share/cmake/nlp-engine")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

set(VERSION 2.9.3)

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO couchbase/libcouchbase
  REF 2.9.3
  SHA512 79b842967beaec0f26244b8ea18fa588d00356e04c47c052234cb15a2b3b1b2134e9d8cad5f5c1958321ec0c762b59785d37b2ac275e80eab5693b7dd252bceb
  HEAD_REF master
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DLCB_NO_TESTS=ON
        -DLCB_NO_TOOLS=ON
        -DLCB_NO_PLUGINS=ON

)
vcpkg_cmake_install()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
   
file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

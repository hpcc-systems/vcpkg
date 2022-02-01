vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO seznam/elasticlient
    REF d68e30e382b5f2817be8cd901494736b26d4896e
    SHA512 703b13cfd4346de934ace6d62e2bd5d0bfec3c06c1061b842c1477ce260a816ec8a128b337c91a1cf4e79aca7c73d28d591c56d4c725ee3b77a7cb1c2bee4663
    HEAD_REF master
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"

    OPTIONS 
        -DBUILD_ELASTICLIENT_TESTS=0 
        -DBUILD_ELASTICLIENT_EXAMPLE=0 
        -DUSE_SYSTEM_JSONCPP=1 
        -DUSE_SYSTEM_CPR=1
        -DBUILD_SHARED_LIBS=OFF
)

vcpkg_cmake_install()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${SOURCE_PATH}/LICENSE.txt" DESTINATION "${CURRENT_PACKAGES_DIR}/share/elasticlient" RENAME copyright)

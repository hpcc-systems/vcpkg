include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH CURRENT_BUILDTREES_DIR
    REPO hpcc-systems/gsoap
    REF v${VERSION}
    SHA512 47cb6b382737edab18f00d4adb62dd9dd7ef9fbe16f46e173fed9861fea4cb516660cab865be46adcc6a81947aa9faac709d9b4c8a0367828413a04a42143d9b
    HEAD_REF master
)

file(COPY ${CURRENT_BUILDTREES_DIR}/gsoap DESTINATION ${CURRENT_PACKAGES_DIR}/share)

file(COPY ${CURRENT_BUILDTREES_DIR}/gsoap/stdsoap2.h DESTINATION ${CURRENT_PACKAGES_DIR}/include/gsoap)

file(INSTALL ${CURRENT_BUILDTREES_DIR}/license.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/gsoap RENAME copyright)

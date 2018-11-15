# Common Ambient Variables:
#   CURRENT_BUILDTREES_DIR    = ${VCPKG_ROOT_DIR}\buildtrees\${PORT}
#   CURRENT_PACKAGES_DIR      = ${VCPKG_ROOT_DIR}\packages\${PORT}_${TARGET_TRIPLET}
#   CURRENT_PORT_DIR          = ${VCPKG_ROOT_DIR}\ports\${PORT}
#   PORT                      = current port name (zlib, etc)
#   TARGET_TRIPLET            = current triplet (x86-windows, x64-windows-static, etc)
#   VCPKG_CRT_LINKAGE         = C runtime linkage type (static, dynamic)
#   VCPKG_LIBRARY_LINKAGE     = target library linkage type (static, dynamic)
#   VCPKG_ROOT_DIR            = <C:\path\to\current\vcpkg>
#   VCPKG_TARGET_ARCHITECTURE = target architecture (x64, x86, arm)
#

include(vcpkg_common_functions)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/gsoap_2.7.13)
vcpkg_download_distfile(ARCHIVE
    URLS "https://sourceforge.net/projects/gsoap2/files/gsoap-2.7/gsoap_2.7.13.zip/download"
    FILENAME "gsoap_2.7.13.zip"
    SHA512  9d10fde082ac1b20cbf0713f813d118e60bc5b3a9136d99915959a06c8e67aa9983524c0c18a26fc0430a63d82c5c5d83717f8437c1433c2068f2ee34de40ccf
)
vcpkg_extract_source_archive(${ARCHIVE})

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/include ${CURRENT_PACKAGES_DIR}/src)

file(COPY ${CURRENT_BUILDTREES_DIR}/src/gsoap-2.7/gsoap/stdsoap2.h DESTINATION ${CURRENT_PACKAGES_DIR}/include/gsoap)

file(INSTALL ${CURRENT_BUILDTREES_DIR}/src/gsoap-2.7/license.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/gsoap RENAME copyright)


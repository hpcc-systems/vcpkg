vcpkg_download_distfile(ARCHIVE
    URLS "https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.5.13.tgz"
    FILENAME "openldap-2.5.13.tgz"
    SHA512 30fdc884b513c53169910eec377c2ad05013b9f06bab3123d50d028108b24548791f7f47f18bcb3a2b4868edeab02c10d81ffa320c02d7b562f2e8f2fa25d6c9
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    set(BUILD_OPTS --enable-shared=yes --enable-static=no)
else()
    set(BUILD_OPTS --enable-shared=no --enable-static=yes)
endif()

vcpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
    ${BUILD_OPTS}
    --without-cyrus-sasl
)

vcpkg_install_make()
vcpkg_fixup_pkgconfig()
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/var")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/var")

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/openldap" RENAME copyright)

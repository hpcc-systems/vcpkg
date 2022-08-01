vcpkg_download_distfile(ARCHIVE
    URLS "https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.5.13.tgz"
    FILENAME "openldap-2.5.13.tgz"
    SHA512 30fdc884b513c53169910eec377c2ad05013b9f06bab3123d50d028108b24548791f7f47f18bcb3a2b4868edeab02c10d81ffa320c02d7b562f2e8f2fa25d6c9
)

execute_process(COMMAND bash "-c" "awk -F= '/^NAME/{print $2}' \"/etc/os-release\""
    OUTPUT_VARIABLE OS_RELEASE
    ERROR_VARIABLE OS_RELEASE_ERROR
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
message("OS_RELEASE (OS_RELEASE_ERROR): ${OS_RELEASE} (${OS_RELEASE_ERROR})")

if(OS_RELEASE STREQUAL "\"CentOS Linux\"")
    vcpkg_extract_source_archive_ex(
        OUT_SOURCE_PATH SOURCE_PATH
        ARCHIVE ${ARCHIVE}
        PATCHES
        openssl.patch
        m4.patch
    )
else()
    vcpkg_extract_source_archive_ex(
        OUT_SOURCE_PATH SOURCE_PATH
        ARCHIVE ${ARCHIVE}
        PATCHES
        openssl.patch
    )
endif()

if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    set(BUILD_OPTS --enable-shared=yes --enable-static=no)
else()
    set(BUILD_OPTS --enable-shared=no --enable-static=yes)
endif()

vcpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    AUTOCONFIG

    # PRERUN_SHELL autoreconf --force --install
    OPTIONS
    ${BUILD_OPTS}
    --disable-slapd
    --with-tls=openssl
    --without-cyrus-sasl
    "LIBS=-ldl"

    # --enable-slapd
    # --enable-modules
    # --enable-rlookups
    # --enable-backends=mod
    # --disable-ndb
    # --disable-sql
    # --enable-overlays=mod
)

vcpkg_build_make(BUILD_TARGET depend)
vcpkg_build_make()
vcpkg_install_make()
vcpkg_fixup_pkgconfig()
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/var")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/var")

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/openldap" RENAME copyright)

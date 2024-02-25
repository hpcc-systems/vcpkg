if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO open-telemetry/opentelemetry-cpp
    REF "v${VERSION}"
    SHA512 86cf0320f9ee50bc1aa2b7a8b254fb0df25d1bd1f5f01ebc3630ab7fe2f6ca5e53ca8e042518b4e7096dbb102c0b880e9a25fcdf5f668d24ff57d9247237bf62
    HEAD_REF main
    PATCHES
        # Use the compiler's default C++ version. Picking a version with
        # CMAKE_CXX_STANDARD is not needed as the Abseil port already picked
        # one and propagates that version across all its downstream deps.
        use-default-cxx-version.patch
        # When compiling code generated by gRPC we need to link the gRPC library
        # too.
        add-missing-dependencies.patch
        # Missing find_dependency for Abseil
        add-missing-find-dependency.patch
        # HPCC-fix: Remove code that reinitialised the random number generator on fork()
        hpcc-remove-unsafe-onfork.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        etw WITH_ETW
        zipkin WITH_ZIPKIN
        prometheus WITH_PROMETHEUS
        elasticsearch WITH_ELASTICSEARCH
        jaeger WITH_JAEGER
        otlp WITH_OTLP
        otlp-http WITH_OTLP_HTTP
        zpages WITH_ZPAGES
        otlp-grpc WITH_OTLP_GRPC
)

# opentelemetry-proto is a third party submodule and opentelemetry-cpp release did not pack it.
if(WITH_OTLP)
    set(OTEL_PROTO_VERSION "0.19.0")
    vcpkg_download_distfile(ARCHIVE
        URLS "https://github.com/open-telemetry/opentelemetry-proto/archive/v${OTEL_PROTO_VERSION}.tar.gz"
        FILENAME "opentelemetry-proto-${OTEL_PROTO_VERSION}.tar.gz"
        SHA512 b6d47aaa90ff934eb24047757d5fdb8a5be62963a49b632460511155f09a725937fb7535cf34f738b81cc799600adbbc3809442aba584d760891c0a1f0ce8c03
    )

    vcpkg_extract_source_archive(src ARCHIVE "${ARCHIVE}")
    file(REMOVE_RECURSE "${SOURCE_PATH}/third_party/opentelemetry-proto")
    file(COPY "${src}/." DESTINATION "${SOURCE_PATH}/third_party/opentelemetry-proto")
    # Create empty .git directory to prevent opentelemetry from cloning it during build time
    file(MAKE_DIRECTORY "${SOURCE_PATH}/third_party/opentelemetry-proto/.git")
    list(APPEND FEATURE_OPTIONS -DCMAKE_CXX_STANDARD=14)
    list(APPEND FEATURE_OPTIONS -DgRPC_CPP_PLUGIN_EXECUTABLE=${CURRENT_HOST_INSTALLED_DIR}/tools/grpc/grpc_cpp_plugin${VCPKG_HOST_EXECUTABLE_SUFFIX})
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTING=OFF
        -DWITH_EXAMPLES=OFF
        -DWITH_LOGS_PREVIEW=ON
        -DOPENTELEMETRY_INSTALL=ON
        -DWITH_ABSEIL=ON
        ${FEATURE_OPTIONS}
    MAYBE_UNUSED_VARIABLES
        WITH_OTLP_GRPC
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/${PORT})
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")

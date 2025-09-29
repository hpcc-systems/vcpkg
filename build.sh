#!/bin/sh -e

normalize_arch() {
    case "$1" in
        x86_64|amd64|x64)
            echo "x64"
            ;;
        i386|i686|x86)
            echo "x86"
            ;;
        arm64|aarch64)
            echo "arm64"
            ;;
        armv7l|armv7|armhf|arm)
            echo "arm"
            ;;
        *)
            return 1
            ;;
    esac
}

normalize_os() {
    case "$1" in
        Darwin|darwin|macos|osx)
            echo "osx"
            ;;
        Linux|linux)
            echo "linux"
            ;;
        MINGW*|MSYS*|CYGWIN*|Windows_NT|windows|win|win32)
            echo "windows"
            ;;
        *)
            return 1
            ;;
    esac
}

infer_windows_native_arch() {
    hint_text="$1 $2 $3 $4"
    hint_text_upper="$(printf '%s' "$hint_text" | tr '[:lower:]' '[:upper:]')"

    case "$hint_text_upper" in
        *ARM64*|*AARCH64*)
            echo "arm64"
            ;;
        *ARM*)
            echo "arm"
            ;;
        *)
            return 1
            ;;
    esac
}

triplet_for() {
    arch="$1"
    os="$2"

    case "$os" in
        osx)
            echo "${arch}-osx"
            ;;
        linux)
            echo "${arch}-linux-dynamic"
            ;;
        windows)
            echo "${arch}-windows"
            ;;
        *)
            return 1
            ;;
    esac
}

usage() {
    cat <<EOF
Usage: ./build.sh [--arch <x86|x64|arm|arm64>] [--os <windows|linux|osx>] [--triplet <triplet>]

Overrides can also be set via environment variables:
  VCPKG_TARGET_ARCH
  VCPKG_TARGET_OS
  VCPKG_TARGET_TRIPLET

If --triplet (or VCPKG_TARGET_TRIPLET) is provided, --arch/--os (and VCPKG_TARGET_ARCH/VCPKG_TARGET_OS) are ignored.
EOF
}

target_arch_override="${VCPKG_TARGET_ARCH:-}"
target_os_override="${VCPKG_TARGET_OS:-}"
target_triplet="${VCPKG_TARGET_TRIPLET:-}"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --arch)
            if [ "$#" -lt 2 ]; then
                echo "Missing value for --arch" >&2
                usage
                exit 1
            fi
            target_arch_override="$2"
            shift 2
            ;;
        --os)
            if [ "$#" -lt 2 ]; then
                echo "Missing value for --os" >&2
                usage
                exit 1
            fi
            target_os_override="$2"
            shift 2
            ;;
        --triplet)
            if [ "$#" -lt 2 ]; then
                echo "Missing value for --triplet" >&2
                usage
                exit 1
            fi
            target_triplet="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 1
            ;;
    esac
done

detected_os_raw="$(uname -s)"
detected_arch_raw="$(uname -m)"

if ! host_os="$(normalize_os "$detected_os_raw")"; then
    echo "Unsupported host OS from uname -s: $detected_os_raw" >&2
    exit 1
fi

detected_arch_effective="$detected_arch_raw"
host_arch_source="uname -m"

if [ "$host_os" = "windows" ]; then
    if windows_native_arch="$(infer_windows_native_arch "$detected_os_raw" "${PROCESSOR_ARCHITECTURE:-}" "${PROCESSOR_ARCHITEW6432:-}" "${MSYSTEM:-}")"; then
        if uname_arch_normalized="$(normalize_arch "$detected_arch_raw")"; then
            case "$uname_arch_normalized" in
                x86|x64)
                    detected_arch_effective="$windows_native_arch"
                    host_arch_source="windows native hints"
                    ;;
            esac
        else
            detected_arch_effective="$windows_native_arch"
            host_arch_source="windows native hints"
        fi
    fi
fi

if ! host_arch="$(normalize_arch "$detected_arch_effective")"; then
    echo "Unsupported host architecture from detection: raw='$detected_arch_raw' effective='$detected_arch_effective'" >&2
    exit 1
fi

if ! host_triplet="$(triplet_for "$host_arch" "$host_os")"; then
    echo "Failed to determine host triplet for $host_arch/$host_os" >&2
    exit 1
fi

if [ -z "$target_triplet" ]; then
    target_arch="$host_arch"
    target_os="$host_os"

    if [ -n "$target_arch_override" ]; then
        if ! target_arch="$(normalize_arch "$target_arch_override")"; then
            echo "Unsupported target architecture override: $target_arch_override" >&2
            exit 1
        fi
    fi

    if [ -n "$target_os_override" ]; then
        if ! target_os="$(normalize_os "$target_os_override")"; then
            echo "Unsupported target OS override: $target_os_override" >&2
            exit 1
        fi
    fi

    if ! target_triplet="$(triplet_for "$target_arch" "$target_os")"; then
        echo "Failed to determine target triplet for $target_arch/$target_os" >&2
        exit 1
    fi
fi

echo "Detected host uname: os='$detected_os_raw' arch='$detected_arch_raw'"
echo "Detected host arch source: '$host_arch_source' (effective='$detected_arch_effective')"
echo "Resolved host: os='$host_os' arch='$host_arch' triplet='$host_triplet'"
echo "Target triplet: '$target_triplet'"
if [ "$host_triplet" = "$target_triplet" ]; then
    echo "Cross compile: no"
else
    echo "Cross compile: yes"
fi

./bootstrap-vcpkg.sh

./vcpkg install \
    --x-abi-tools-use-exact-versions \
    --downloads-root=./build/vcpkg_downloads \
    --x-buildtrees-root=./build/vcpkg_buildtrees \
    --x-packages-root=./build/vcpkg_packages \
    --x-install-root=./build/vcpkg_installed \
    --host-triplet="$host_triplet" \
    --triplet="$target_triplet"

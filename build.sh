#!/bin/sh -e

os_name="$(uname -s)"
arch_name="$(uname -m)"

case "$arch_name" in
    x86_64|amd64)
        vcpkg_arch="x64"
        ;;
    arm64|aarch64)
        vcpkg_arch="arm64"
        ;;
    *)
        echo "Unsupported architecture: $arch_name" >&2
        exit 1
        ;;
esac

case "$os_name" in
    Darwin)
        triplet="${vcpkg_arch}-osx"
        ;;
    Linux)
        triplet="${vcpkg_arch}-linux-dynamic"
        ;;
    MINGW*|MSYS*|CYGWIN*|Windows_NT)
        if [ "$vcpkg_arch" != "x64" ]; then
            echo "Windows builds in this script currently support x64 only" >&2
            exit 1
        fi
        triplet="x64-windows"
        ;;
    *)
        echo "Unsupported OS: $os_name" >&2
        exit 1
        ;;
esac

./bootstrap-vcpkg.sh

./vcpkg install \
    --x-abi-tools-use-exact-versions \
    --downloads-root=./build/vcpkg_downloads \
    --x-buildtrees-root=./build/vcpkg_buildtrees \
    --x-packages-root=./build/vcpkg_packages \
    --x-install-root=./build/vcpkg_installed \
    --host-triplet="$triplet" \
    --triplet="$triplet"

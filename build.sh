#!/bin/sh -e

./bootstrap-vcpkg.sh

./vcpkg install \
    --x-abi-tools-use-exact-versions \
    --downloads-root=./build/vcpkg_downloads \
    --x-buildtrees-root=./build/vcpkg_buildtrees \
    --x-packages-root=./build/vcpkg_packages \
    --x-install-root=./build/vcpkg_installed \
    --host-triplet=x86-windows \
    --triplet=x86-windows

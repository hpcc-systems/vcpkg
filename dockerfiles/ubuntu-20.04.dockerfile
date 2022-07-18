FROM ubuntu:20.04 AS BASE_OS

ENV DEBIAN_FRONTEND=noninteractive
ENV VCPKG_BINARY_SOURCES="clear;nuget,GitHub,readwrite"
ENV VCPKG_NUGET_REPOSITORY=https://github.com/hpcc-systems/vcpkg

# Build Tools - Mono  ---
RUN apt update
RUN apt install -y dirmngr gnupg apt-transport-https ca-certificates software-properties-common
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN sh -c 'echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" > /etc/apt/sources.list.d/mono-official-stable.list'
RUN apt update
RUN apt install -y mono-complete

# Build Tools  ---
RUN apt install -y git curl zip unzip tar
RUN apt install -y build-essential autoconf libtool

# Libraries  ---
RUN apt install -y libncurses-dev

WORKDIR /hpcc-dev

RUN git clone -n https://github.com/hpcc-systems/vcpkg.git

WORKDIR /hpcc-dev/vcpkg
ARG BUILD_BRANCH=hpcc-platform-8.8.x
RUN git checkout ${BUILD_BRANCH}
RUN /hpcc-dev/vcpkg/bootstrap-vcpkg.sh

ARG GITHUB_ACTOR=hpcc-systems
ARG GITHUB_TOKEN=none
RUN mono `/hpcc-dev/vcpkg/vcpkg fetch nuget | tail -n 1` \
    sources add \
    -name "GitHub" \
    -source "https://nuget.pkg.github.com/hpcc-systems/index.json" \
    -storepasswordincleartext \
    -username "${GITHUB_ACTOR}" \
    -password "${GITHUB_TOKEN}"
RUN mono `/hpcc-dev/vcpkg/vcpkg fetch nuget | tail -n 1` \
    setapikey "${GITHUB_TOKEN}" \
    -source "https://nuget.pkg.github.com/hpcc-systems/index.json"

# vcpkg  ---
WORKDIR /hpcc-dev/build
RUN /hpcc-dev/vcpkg/vcpkg install \
    --clean-after-build \
    --overlay-ports=/hpcc-dev/vcpkg/overlays \
    --x-manifest-root=/hpcc-dev/vcpkg \
    --downloads-root=/hpcc-dev/build/vcpkg_downloads \
    --x-buildtrees-root=/hpcc-dev/build/vcpkg_buildtrees \
    --x-packages-root=/hpcc-dev/build/vcpkg_packages

RUN mono `/hpcc-dev/vcpkg/vcpkg fetch nuget | tail -n 1` \
    sources remove \
    -name "GitHub"

FROM ubuntu:20.04
COPY --from=BASE_OS /hpcc-dev/build /hpcc-dev/build

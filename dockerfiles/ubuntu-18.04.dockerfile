FROM ubuntu:18.04 AS BASE_OS

ENV DEBIAN_FRONTEND=noninteractive

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
RUN apt install -y groff-base

WORKDIR /hpcc-dev/HPCC-Platform

ARG GITHUB_OWNER=hpcc-systems
ARG GITHUB_REF=hpcc-platform-8.8.x
RUN git clone -n https://github.com/${GITHUB_OWNER}/vcpkg.git

WORKDIR /hpcc-dev/HPCC-Platform/vcpkg
RUN git checkout ${GITHUB_REF}
RUN /hpcc-dev/HPCC-Platform/vcpkg/bootstrap-vcpkg.sh

ENV VCPKG_BINARY_SOURCES="clear;nuget,GitHub,readwrite"
ENV VCPKG_NUGET_REPOSITORY=https://github.com/hpcc-systems/vcpkg

ARG GITHUB_ACTOR=hpcc-systems
ARG GITHUB_TOKEN=none
RUN mono `./vcpkg fetch nuget | tail -n 1` \
    sources add \
    -name "GitHub" \
    -source "https://nuget.pkg.github.com/hpcc-systems/index.json" \
    -storepasswordincleartext \
    -username "${GITHUB_ACTOR}" \
    -password "${GITHUB_TOKEN}"
RUN mono `./vcpkg fetch nuget | tail -n 1` \
    setapikey "${GITHUB_TOKEN}" \
    -source "https://nuget.pkg.github.com/hpcc-systems/index.json"

# vcpkg  ---
RUN ./vcpkg install \
    --clean-after-build \
    --overlay-ports=./overlays || echo " *** vcpkg install failed ***"

# RUN mono `/hpcc-dev/HPCC-Platform/vcpkg/vcpkg fetch nuget | tail -n 1` \
#     sources remove \
#     -name "GitHub"

# FROM ubuntu:18.04
# COPY --from=BASE_OS /hpcc-dev/build /hpcc-dev/build

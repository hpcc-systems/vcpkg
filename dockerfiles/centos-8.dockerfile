FROM centos:centos8.4.2105 AS BASE_OS

ENV VCPKG_BINARY_SOURCES="clear;nuget,GitHub,readwrite"
ENV VCPKG_NUGET_REPOSITORY=https://github.com/hpcc-systems/vcpkg

RUN cd /etc/yum.repos.d/
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# Build Tools - Mono  ---
RUN yum update -y
RUN yum install -y yum-utils
RUN yum-config-manager --add-repo http://download.mono-project.com/repo/centos/
RUN yum clean all
RUN yum makecache
RUN rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
RUN dnf config-manager --add-repo https://download.mono-project.com/repo/centos8-stable.repo
RUN dnf install -y mono-complete 

# Build Tools  ---
RUN yum install -y git curl zip unzip tar
RUN yum group install -y "Development Tools"
RUN dnf -y install gcc-toolset-9-gcc gcc-toolset-9-gcc-c++

RUN echo "source /opt/rh/gcc-toolset-9/enable" >> /etc/bashrc
SHELL ["/bin/bash", "--login", "-c"]

# Libraries  ---
RUN yum install -y ncurses-devel

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

FROM centos:centos8.4.2105
COPY --from=BASE_OS /hpcc-dev/build /hpcc-dev/build

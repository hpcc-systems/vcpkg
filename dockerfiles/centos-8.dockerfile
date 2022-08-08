FROM centos:centos8.4.2105 AS BASE_OS

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
RUN yum install -y git curl zip unzip tar python3 libtool autoconf automake
RUN yum group install -y "Development Tools"
RUN dnf -y install gcc-toolset-9-gcc gcc-toolset-9-gcc-c++

RUN echo "source /opt/rh/gcc-toolset-9/enable" >> /etc/bashrc
SHELL ["/bin/bash", "--login", "-c"]

# Libraries  ---

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

# FROM centos:centos8.4.2105
# COPY --from=BASE_OS /hpcc-dev/build /hpcc-dev/build

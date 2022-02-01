FROM centos:centos7 AS base_build

# Build Tools  ---
RUN yum update -y && yum install -y \
    centos-release-scl \
    https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm && \
    yum group install -y "Development Tools" && yum install -y \
    autoconf \
    autoconf-archive \
    automake \
    git \
    curl \
    libtool \
    perl-IPC-Cmd \
    python3 \
    unzip \
    tar \
    yum-utils \
    zip 

RUN yum install -y devtoolset-9

RUN echo "source /opt/rh/devtoolset-9/enable" >> /etc/bashrc
SHELL ["/bin/bash", "--login", "-c"]

RUN curl -o pkg-config-0.29.2.tar.gz https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz && \
    tar xvfz pkg-config-0.29.2.tar.gz
WORKDIR /pkg-config-0.29.2
RUN ./configure --prefix=/usr/local/pkg_config/0_29_2 --with-internal-glib && \
    make && \
    make install && \
    ln -s /usr/local/pkg_config/0_29_2/bin/pkg-config /usr/local/bin/ && \
    mkdir /usr/local/share/aclocal && \
    ln -s /usr/local/pkg_config/0_29_2/share/aclocal/pkg.m4 /usr/local/share/aclocal/
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
ENV ACLOCAL_PATH=/usr/local/share/aclocal:$ACLOCAL_PATH

FROM base_build AS vcpkg_build

# Build Tools - Mono  ---
RUN yum-config-manager --add-repo http://download.mono-project.com/repo/centos/
RUN yum clean all
RUN yum makecache
RUN rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"

RUN yum install -y mono-complete 

ARG NUGET_MODE=readwrite
ENV VCPKG_BINARY_SOURCES="clear;nuget,GitHub,${NUGET_MODE}"
ENV VCPKG_NUGET_REPOSITORY=https://github.com/hpcc-systems/vcpkg

COPY . /hpcc-dev/vcpkg

WORKDIR /hpcc-dev/vcpkg

RUN ./bootstrap-vcpkg.sh

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
RUN mkdir /hpcc-dev/build
RUN ./vcpkg install \
    --x-install-root=/hpcc-dev/build/vcpkg_installed \
    --overlay-ports=./overlays \
    --triplet=x64-linux-dynamic
# ./vcpkg install --x-install-root=/hpcc-dev/build/vcpkg_installed --overlay-ports=./overlays --triplet=x64-linux-dynamic

RUN mkdir -p /hpcc-dev/tools/cmake
RUN cp -r $(dirname $(dirname `./vcpkg fetch cmake | tail -n 1`))/* /hpcc-dev/tools/cmake
RUN mkdir -p /hpcc-dev/tools/ninja
RUN cp -r $(dirname `./vcpkg fetch ninja | tail -n 1`)/* /hpcc-dev/tools/ninja
RUN mkdir -p /hpcc-dev/tools/node
RUN cp -r $(dirname $(dirname `./vcpkg fetch node | tail -n 1`))/* /hpcc-dev/tools/node

FROM base_build

WORKDIR /hpcc-dev

COPY --from=vcpkg_build /hpcc-dev/build/vcpkg_installed /hpcc-dev/vcpkg_installed
COPY --from=vcpkg_build /hpcc-dev/tools /hpcc-dev/tools

RUN ln -s /hpcc-dev/tools/cmake/bin/cmake /usr/local/bin/cmake && \
    ln -s /hpcc-dev/tools/ninja/ninja /usr/local/bin/ninja && \
    ln -s /hpcc-dev/tools/node/bin/node /usr/local/bin/node && \
    ln -s /hpcc-dev/tools/node/bin/npm /usr/local/bin/npm && \
    ln -s /hpcc-dev/tools/node/bin/npx /usr/local/bin/npx

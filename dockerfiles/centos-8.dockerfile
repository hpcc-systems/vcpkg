FROM tgagor/centos-stream:stream8 AS base_build

RUN yum update -y && yum install -y dnf-plugins-core && \
    dnf config-manager --set-enabled powertools && \
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

RUN yum -y install gcc-toolset-11-gcc gcc-toolset-11-gcc-c++

RUN echo "source /opt/rh/gcc-toolset-11/enable" >> /etc/bashrc
SHELL ["/bin/bash", "--login", "-c"]

FROM base_build AS vcpkg_build

# Build Tools - Mono  ---
RUN yum-config-manager --add-repo http://download.mono-project.com/repo/centos/
RUN yum clean all
RUN yum makecache
RUN rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"

RUN dnf config-manager --add-repo https://download.mono-project.com/repo/centos8-stable.repo

RUN dnf install -y mono-complete 

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
# ./vcpkg install --overlay-ports=./overlays --triplet=x64-linux-dynamic --x-install-root=/hpcc-dev/build/vcpkg_installed

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

RUN cp -rs /hpcc-dev/tools/cmake/bin /usr/local/ && \
    cp -rs /hpcc-dev/tools/cmake/share /usr/local/ && \
    ln -s /hpcc-dev/tools/ninja/ninja /usr/local/bin/ninja && \
    cp -rs /hpcc-dev/tools/node/bin /usr/local/ && \
    cp -rs /hpcc-dev/tools/node/include /usr/local/ && \
    cp -rs /hpcc-dev/tools/node/lib /usr/local/ && \
    cp -rs /hpcc-dev/tools/node/share /usr/local/

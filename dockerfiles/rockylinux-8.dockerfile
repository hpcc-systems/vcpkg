FROM rockylinux:8 AS base_build

RUN dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled powertools && \
    dnf update -y && \
    dnf install -y --allowerasing \
    autoconf \
    autoconf-archive \
    automake \
    bison \
    curl \
    flex \
    git \
    libtool \
    perl-IPC-Cmd \
    python3 \
    rpm-build \
    tar \
    unzip \
    zip && \
    dnf clean all

RUN dnf install -y gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc

RUN echo "source /opt/rh/gcc-toolset-12/enable" >> /etc/bashrc
SHELL ["/bin/bash", "--login", "-c"]

FROM base_build AS vcpkg_build

# Build Tools - Mono  ---
RUN dnf install -y 'dnf-command(config-manager)'
RUN rpmkeys --import "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF" && \
    dnf config-manager --add-repo https://download.mono-project.com/repo/centos8-stable/ && \
    dnf clean all && \
    dnf makecache && \
    dnf install -y mono-complete

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
    --x-abi-tools-use-exact-versions \
    --x-install-root=/hpcc-dev/build/vcpkg_installed \
    --host-triplet=x64-linux-dynamic \
    --triplet=x64-linux-dynamic
# ./vcpkg install --x-abi-tools-use-exact-versions --x-install-root=/hpcc-dev/build/vcpkg_installed --triplet=x64-linux-dynamic

RUN mkdir -p /hpcc-dev/tools/cmake
RUN cp -r $(dirname $(dirname `./vcpkg fetch cmake | tail -n 1`))/* /hpcc-dev/tools/cmake
RUN mkdir -p /hpcc-dev/tools/ninja
RUN cp -r $(dirname `./vcpkg fetch ninja | tail -n 1`)/* /hpcc-dev/tools/ninja
RUN mkdir -p /hpcc-dev/tools/node
RUN cp -r $(dirname $(dirname `./vcpkg fetch node | tail -n 1`))/* /hpcc-dev/tools/node

FROM base_build

RUN yum remove -y python3.11 java-1.* && yum install -y \
    java-11-openjdk-devel \
    python3-devel \
    epel-release && \
    yum update -y && yum install -y \
    ccache \
    R-core-devel \
    R-Rcpp-devel \
    R-RInside-devel && \
    yum -y clean all && rm -rf /var/cache

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

ENTRYPOINT ["/bin/bash", "--login", "-c"]

CMD ["/bin/bash"]

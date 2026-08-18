FROM rockylinux/rockylinux:10 AS base_build

RUN dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled crb && \
    dnf update -y && \
    dnf install -y --allowerasing \
    autoconf \
    autoconf-archive \
    automake \
    bison \
    curl \
    flex \
    gcc \
    gcc-c++ \
    binutils \
    annobin-annocheck \
    annobin-plugin-gcc \
    epel-release \
    git \
    kernel-headers \
    libtool \
    libtirpc-devel \
    perl-FindBin \
    perl-IPC-Cmd \
    perl-Time-Piece \
    python3 \
    rpm-build \
    tar \
    unzip \
    zip && \
    dnf clean all

WORKDIR /hpcc-dev
RUN chmod -R 777 /hpcc-dev

FROM base_build AS vcpkg_build

# Build Tools - Mono  ---
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
    --x-abi-tools-use-exact-versions \
    --downloads-root=/hpcc-dev/vcpkg_downloads \
    --x-buildtrees-root=/hpcc-dev/vcpkg_buildtrees \
    --x-packages-root=/hpcc-dev/vcpkg_packages \
    --x-install-root=/hpcc-dev/vcpkg_installed \
    --host-triplet=x64-linux-dynamic \
    --triplet=x64-linux-dynamic

# ./vcpkg install --x-abi-tools-use-exact-versions --x-install-root=/hpcc-dev/build/vcpkg_installed --host-triplet=x64-linux-dynamic --triplet=x64-linux-dynamic

RUN mkdir -p /hpcc-dev/tools/cmake
RUN cp -r $(dirname $(dirname `./vcpkg fetch cmake | tail -n 1`))/* /hpcc-dev/tools/cmake
RUN mkdir -p /hpcc-dev/tools/ninja
RUN cp -r $(dirname `./vcpkg fetch ninja | tail -n 1`)/* /hpcc-dev/tools/ninja
RUN mkdir -p /hpcc-dev/tools/node
RUN cp -r $(dirname $(dirname `./vcpkg fetch node | tail -n 1`))/* /hpcc-dev/tools/node

FROM base_build

RUN yum install -y \
    java-devel \
    python3-devel \
    ccache \
    R-core-devel \
    R-Rcpp-devel \
    R-RInside-devel && \
    yum -y clean all && rm -rf /var/cache

WORKDIR /hpcc-dev

COPY --from=vcpkg_build /hpcc-dev/vcpkg_installed /hpcc-dev/vcpkg_installed
COPY --from=vcpkg_build /hpcc-dev/tools /hpcc-dev/tools

RUN cp -rs /hpcc-dev/tools/cmake/bin /usr/local/ && \
    cp -rs /hpcc-dev/tools/cmake/share /usr/local/ && \
    ln -s /hpcc-dev/tools/ninja/ninja /usr/local/bin/ninja

RUN curl -fsSL https://rpm.nodesource.com/setup_22.x | bash - && \
    yum install -y \
    nodejs && \
    yum -y clean all && rm -rf /var/cache 

ENTRYPOINT ["/bin/bash", "--login", "-c"]

CMD ["/bin/bash"]

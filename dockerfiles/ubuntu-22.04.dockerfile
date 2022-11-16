ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE} AS base_build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    autoconf \
    autoconf-archive \
    automake \
    autotools-dev \
    binutils-dev \
    bison \
    build-essential \
    ca-certificates \
    curl \
    dirmngr \
    flex \
    git \
    gnupg \
    groff-base \
    libtool \
    pkg-config \
    software-properties-common \
    tar \
    unzip \
    uuid-dev \
    zip

FROM base_build AS vcpkg_build

# Build Tools - Mono  ---
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN sh -c 'echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" > /etc/apt/sources.list.d/mono-official-stable.list'
RUN apt-get update && apt-get install --no-install-recommends -y \
    cmake \
    mono-complete \
    ninja-build

ARG TRIPLET=x64-linux-dynamic
ARG NUGET_MODE=readwrite
ENV VCPKG_DEFAULT_HOST_TRIPLET=${TRIPLET}
ENV VCPKG_DEFAULT_TRIPLET=${TRIPLET}
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
    --host-triplet=${TRIPLET} \
    --triplet=${TRIPLET}
# ./vcpkg install --x-abi-tools-use-exact-versions --x-install-root=/hpcc-dev/build/vcpkg_installed --host-triplet=x64-linux-dynamic --triplet=x64-linux-dynamic

RUN mkdir -p /hpcc-dev/tools/cmake
RUN cp -r $(dirname $(dirname `./vcpkg fetch cmake | tail -n 1`))/. /hpcc-dev/tools/cmake

FROM base_build

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get update && apt-get install --no-install-recommends -y \
    ccache \
    default-jdk \
    ninja-build \
    nodejs \
    python3-dev \
    rsync \
    fop \
    libsaxonb-java \
    r-base \
    r-cran-rcpp \
    r-cran-rinside \
    r-cran-inline && \
    git config --global --add safe.directory '*'

RUN curl -o- https://fnm.vercel.app/install | bash && \
    /root/.local/share/fnm/fnm install 22

WORKDIR /hpcc-dev

COPY --from=vcpkg_build /hpcc-dev/vcpkg_installed /hpcc-dev/vcpkg_installed
COPY --from=vcpkg_build /hpcc-dev/tools/cmake/bin /usr/local/bin
COPY --from=vcpkg_build /hpcc-dev/tools/cmake/share /usr/local/share

ENTRYPOINT ["/bin/bash", "--login", "-c"]

CMD ["/bin/bash"]

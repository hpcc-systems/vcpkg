FROM ubuntu:24.04 AS base_build

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
    libtirpc-dev \
    pkg-config \
    software-properties-common \
    tar \
    unzip \
    uuid-dev \
    zip

WORKDIR /hpcc-dev
RUN chmod -R 777 /hpcc-dev

ARG EMSCRIPTEN_VERSION=5.0.1
RUN git clone https://github.com/emscripten-core/emsdk.git && \
    cd emsdk && \
    ./emsdk install ${EMSCRIPTEN_VERSION} && \
    ./emsdk activate ${EMSCRIPTEN_VERSION} && \
    echo 'source "/hpcc-dev/emsdk/emsdk_env.sh"' >> /etc/profile.d/emsdk_env.sh
SHELL ["/bin/bash", "--login", "-c"]

FROM base_build AS vcpkg_build

# Build Tools - Mono  ---
RUN apt-get update && apt-get install --no-install-recommends -y \
    cmake \
    mono-complete \
    ninja-build

ARG HOST_TRIPLET=x64-linux-dynamic
ARG TRIPLET=wasm32-emscripten
ARG NUGET_MODE=readwrite
ENV VCPKG_DEFAULT_HOST_TRIPLET=${HOST_TRIPLET}
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
    --host-triplet=${HOST_TRIPLET} \
    --triplet=${TRIPLET}
# ./vcpkg install --x-abi-tools-use-exact-versions --host-triplet=x64-linux-dynamic --triplet=wasm32-emscripten

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

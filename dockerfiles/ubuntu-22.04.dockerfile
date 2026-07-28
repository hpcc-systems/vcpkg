ARG BASE_IMAGE=ubuntu:22.04
ARG GO_VERSION=1.26.3
ARG GO_SHA256_AMD64=2b2cfc7148493da5e73981bffbf3353af381d5f93e789c82c79aff64962eb556
ARG GO_SHA256_ARM64=9d89a3ea57d141c2b22d70083f2c8459ba3890f2d9e818e7e933b75614936565
ARG KUBECTL_VERSION=1.36.1
ARG GIT_LFS_VERSION=3.7.1
ARG GO_CRYPTO_VERSION=v0.52.0
ARG GO_NET_VERSION=v0.55.0

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

WORKDIR /hpcc-dev
RUN chmod -R 777 /hpcc-dev

FROM base_build AS go_build

ARG GO_VERSION
ARG GO_SHA256_AMD64
ARG GO_SHA256_ARM64

RUN set -eux; \
	ARCH=$(dpkg --print-architecture); \
	case "${ARCH}" in \
		amd64) GO_SHA256="${GO_SHA256_AMD64}" ;; \
		arm64) GO_SHA256="${GO_SHA256_ARM64}" ;; \
		*) echo "Unsupported architecture: ${ARCH}" >&2 && exit 1 ;; \
	esac; \
	curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" -o go.tar.gz; \
	echo "${GO_SHA256}  go.tar.gz" | sha256sum -c -; \
	tar -C /usr/local -xzf go.tar.gz; \
	rm go.tar.gz; \
	/usr/local/go/bin/go version

FROM go_build AS go_tools_build

ARG KUBECTL_VERSION
ARG GIT_LFS_VERSION
ARG GO_CRYPTO_VERSION
ARG GO_NET_VERSION

# Build Kubernetes kubectl
RUN set -eux; \
	git clone --depth 1 --branch "v${KUBECTL_VERSION}" https://github.com/kubernetes/kubernetes.git /tmp/kubernetes-src; \
	cd /tmp/kubernetes-src; \
	GOPROXY=direct GOSUMDB=off GOWORK=off /usr/local/go/bin/go mod edit -require=golang.org/x/net@${GO_NET_VERSION}; \
	GOPROXY=direct GOSUMDB=off GOWORK=off /usr/local/go/bin/go build -mod=mod -o /usr/local/bin/kubectl ./cmd/kubectl; \
	test -x /usr/local/bin/kubectl; \
	rm -rf /tmp/kubernetes-src

# Build git-lfs
RUN set -eux; \
	git clone --depth 1 --branch "v${GIT_LFS_VERSION}" https://github.com/git-lfs/git-lfs.git /tmp/git-lfs; \
	cd /tmp/git-lfs; \
	GOPROXY=direct GOSUMDB=off /usr/local/go/bin/go mod edit -require=golang.org/x/crypto@${GO_CRYPTO_VERSION} -require=golang.org/x/net@${GO_NET_VERSION}; \
	GOPROXY=direct GOSUMDB=off GONOSUMDB='*' /usr/local/go/bin/go mod tidy; \
	GOPROXY=direct GOSUMDB=off /usr/local/go/bin/go build -o /usr/local/bin/git-lfs .; \
	/usr/local/bin/git-lfs version | grep "git-lfs/${GIT_LFS_VERSION}"; \
	rm -rf /root/go /tmp/git-lfs

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
COPY --from=go_tools_build /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=go_tools_build /usr/local/bin/git-lfs /usr/local/bin/git-lfs
COPY --from=go_build /usr/local/go /usr/local/go

ENV PATH="/usr/local/go/bin:${PATH}"

ENTRYPOINT ["/bin/bash", "--login", "-c"]

CMD ["/bin/bash"]

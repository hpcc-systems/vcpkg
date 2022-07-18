FROM centos:centos7 AS BASE_OS

ENV VCPKG_BINARY_SOURCES="clear;nuget,GitHub,readwrite"
ENV VCPKG_NUGET_REPOSITORY=https://github.com/hpcc-systems/vcpkg

# Build Tools - Mono  ---
RUN yum update -y
RUN yum install -y yum-utils
RUN yum-config-manager --add-repo http://download.mono-project.com/repo/centos/
RUN yum clean all
RUN yum makecache
RUN rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"

RUN yum -y install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm

RUN yum install -y mono-complete 

# Build Tools  ---
RUN yum install -y git curl zip unzip tar
RUN yum group install -y "Development Tools"
RUN yum install -y centos-release-scl
RUN yum install -y devtoolset-9

RUN echo "source /opt/rh/devtoolset-9/enable" >> /etc/bashrc
SHELL ["/bin/bash", "--login", "-c"]

RUN curl -o pkg-config-0.29.2.tar.gz https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
RUN tar xvfz pkg-config-0.29.2.tar.gz
WORKDIR /pkg-config-0.29.2
RUN ./configure --prefix=/usr/local/pkg_config/0_29_2 --with-internal-glib
RUN make
RUN make install
RUN ln -s /usr/local/pkg_config/0_29_2/bin/pkg-config /usr/local/bin/
RUN mkdir /usr/local/share/aclocal
RUN ln -s /usr/local/pkg_config/0_29_2/share/aclocal/pkg.m4 /usr/local/share/aclocal/
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
ENV ACLOCAL_PATH=/usr/local/share/aclocal:$ACLOCAL_PATH

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

FROM centos:centos7
COPY --from=BASE_OS /hpcc-dev/build /hpcc-dev/build

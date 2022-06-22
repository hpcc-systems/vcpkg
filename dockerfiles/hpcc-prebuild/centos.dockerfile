##############################################################################
#
#    HPCC SYSTEMS software Copyright (C) 2022 HPCC Systems®.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
##############################################################################

FROM centos:centos7

RUN yum update -y
RUN yum install -y yum-utils
RUN yum-config-manager --add-repo http://download.mono-project.com/repo/centos/
RUN yum clean all
RUN yum makecache
RUN rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"

RUN yum -y install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm

RUN yum install -y mono-complete git zip unzip wget python3 libtool autoconf automake ncurses-devel
RUN yum group install -y "Development Tools"
RUN yum install -y centos-release-scl
RUN yum install -y devtoolset-9

RUN echo "source /opt/rh/devtoolset-9/enable" >> /etc/bashrc
SHELL ["/bin/bash", "--login", "-c"]

RUN wget https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
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

ARG REPO_OWNER=hpcc-systems
ARG BUILD_BRANCH=hpcc-platform-8.8.x
ARG BUILD_TOKEN=none
RUN echo REPO_OWNER is ${REPO_OWNER}
RUN echo BUILD_BRANCH is ${BUILD_BRANCH}

ENV VCPKG_BINARY_SOURCES="clear;nuget,GitHub,readwrite"
ENV VCPKG_NUGET_REPOSITORY=https://github.com/${REPO_OWNER}/vcpkg

WORKDIR /hpcc-dev

RUN git clone https://github.com/${REPO_OWNER}/vcpkg.git

WORKDIR /hpcc-dev/vcpkg

RUN git checkout ${BUILD_BRANCH}

RUN bash -c "./bootstrap-vcpkg.sh"

RUN mono `./vcpkg fetch nuget | tail -n 1` \
    sources add \
    -source "https://nuget.pkg.github.com/${REPO_OWNER}/index.json" \
    -storepasswordincleartext \
    -name "GitHub" \
    -username "${REPO_OWNER}" \
    -password "${BUILD_TOKEN}"
RUN mono `./vcpkg fetch nuget | tail -n 1` \
    setapikey "${BUILD_TOKEN}" \
    -source "https://nuget.pkg.github.com/${REPO_OWNER}/index.json"

CMD bash -c "./vcpkg install --overlay-ports=./overlays"

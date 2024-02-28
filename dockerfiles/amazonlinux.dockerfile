FROM amazonlinux:2 AS base_build

# Build Tools  ---
RUN yum update -y && yum install -y \
    centos-release-scl \
    wget \
    yum-utils && \
    amazon-linux-extras install -y epel && yum-config-manager --enable epel && \
    yum groupinstall -y "Development Tools" && yum install -y \
    autoconf-archive \
    autoconf \
    automake \
    curl \
    git \
    kernel-devel \
    libtool \
    perl-IPC-Cmd \
    python3 \
    tar \
    unzip \
    zip && \
    yum -y clean all && rm -rf /var/cache

RUN yum-config-manager --add-repo http://mirror.centos.org/centos/7/sclo/x86_64/rh/ && \
    LIBGFORTRAN5=libgfortran5-8.3.1-2.1.1.el7.x86_64.rpm && \
    wget http://mirror.centos.org/centos/7/os/x86_64/Packages/${LIBGFORTRAN5} && \
    yum install -y ${LIBGFORTRAN5} && \
    yum install -y devtoolset-11 --nogpgcheck

RUN echo "source /opt/rh/devtoolset-11/enable" > /etc/profile.d/devtoolset-11.sh
SHELL ["/bin/bash", "--login", "-c"]

RUN yum install -y hostname xz && \
    curl -o pkg-config-0.29.2.tar.gz https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz && \
    tar xvfz pkg-config-0.29.2.tar.gz
WORKDIR /pkg-config-0.29.2
RUN ./configure --prefix=/usr/local/pkg_config/0_29_2 --with-internal-glib && \
    make && \
    make install && \
    ln -s /usr/local/pkg_config/0_29_2/bin/pkg-config /usr/local/bin/ && \
    mkdir /usr/local/share/aclocal && \
    ln -s /usr/local/pkg_config/0_29_2/share/aclocal/pkg.m4 /usr/local/share/aclocal/

ENV PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig
ENV ACLOCAL_PATH=$ACLOCAL_PATH:/usr/local/share/aclocal

RUN curl -o autoconf-2.71.tar.gz http://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz && \
    gunzip autoconf-2.71.tar.gz && \
    tar xvf autoconf-2.71.tar && \
    cd autoconf-2.71 && \
    ./configure && \
    make && \
    make install

RUN curl -o autoconf-archive-2021.02.19.tar.xz http://ftp.gnu.org/gnu/autoconf-archive/autoconf-archive-2021.02.19.tar.xz && \
    xz -d -v autoconf-archive-2021.02.19.tar.xz && \
    tar xvf autoconf-archive-2021.02.19.tar && \
    cd autoconf-archive-2021.02.19 && \
    ./configure && \
    make && \
    make install

RUN curl -o automake-1.16.5.tar.gz http://ftp.gnu.org/gnu/automake/automake-1.16.5.tar.gz && \
    tar xvzf automake-1.16.5.tar.gz && \
    cd automake-1.16.5 && \
    ./configure && \
    make && \
    make install

RUN curl -o libtool-2.4.6.tar.gz http://ftp.jaist.ac.jp/pub/GNU/libtool/libtool-2.4.6.tar.gz && \
    tar xvfz libtool-2.4.6.tar.gz && \
    cd libtool-2.4.6 && \
    ./configure --prefix=/usr/local/libtool/2_4_6 && \
    make && \
    make install

RUN ln -s /usr/local/libtool/2_4_6/bin/libtool /usr/local/bin/ && \
    ln -s /usr/local/libtool/2_4_6/bin/libtoolize /usr/local/bin/ && \
    ln -s /usr/local/libtool/2_4_6/include/libltdl /usr/local/include/ && \
    ln -s /usr/local/libtool/2_4_6/include/ltdl.h /usr/local/include/ && \
    ln -s /usr/local/libtool/2_4_6/lib/libltdl.a /usr/local/lib/ && \
    ln -s /usr/local/libtool/2_4_6/lib/libltdl.la /usr/local/lib/ && \
    ln -s /usr/local/libtool/2_4_6/lib/libltdl.so /usr/local/lib/ && \
    ln -s /usr/local/libtool/2_4_6/lib/libltdl.so.7 /usr/local/lib/ && \
    ln -s /usr/local/libtool/2_4_6/lib/libltdl.so.7.3.1 /usr/local/lib/ && \
    ln -s /usr/local/libtool/2_4_6/share/aclocal/libtool.m4 /usr/local/share/aclocal/ && \
    ln -s /usr/local/libtool/2_4_6/share/aclocal/ltargz.m4 /usr/local/share/aclocal/ && \
    ln -s /usr/local/libtool/2_4_6/share/aclocal/ltdl.m4 /usr/local/share/aclocal/ && \
    ln -s /usr/local/libtool/2_4_6/share/aclocal/lt~obsolete.m4 /usr/local/share/aclocal/ && \
    ln -s /usr/local/libtool/2_4_6/share/aclocal/ltoptions.m4 /usr/local/share/aclocal/ && \
    ln -s /usr/local/libtool/2_4_6/share/aclocal/ltsugar.m4 /usr/local/share/aclocal/ && \
    ln -s /usr/local/libtool/2_4_6/share/aclocal/ltversion.m4 /usr/local/share/aclocal/ 

# echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
# ldconfig
# ldconfig -v

FROM base_build AS vcpkg_build

# Build Tools - Mono  ---
RUN yum-config-manager --add-repo http://download.mono-project.com/repo/centos/ && \
    yum clean all && \
    yum makecache && \
    rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF" && \
    yum install -y mono-complete && \
    yum -y clean all && rm -rf /var/cache

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
    --triplet=x64-amazonlinux-dynamic
# ./vcpkg install --x-abi-tools-use-exact-versions --triplet=x64-amazonlinux-dynamic --x-install-root=/hpcc-dev/build/vcpkg_installed

RUN mkdir -p /hpcc-dev/tools/cmake
RUN cp -r $(dirname $(dirname `./vcpkg fetch cmake | tail -n 1`))/* /hpcc-dev/tools/cmake
RUN mkdir -p /hpcc-dev/tools/ninja
RUN cp -r $(dirname `./vcpkg fetch ninja | tail -n 1`)/* /hpcc-dev/tools/ninja
RUN mkdir -p /hpcc-dev/tools/node
RUN cp -r $(dirname $(dirname `./vcpkg fetch node | tail -n 1`))/* /hpcc-dev/tools/node

FROM base_build

RUN amazon-linux-extras install java-openjdk11 && yum install -y \
    java-11-openjdk-devel \
    python3-devel \
    epel-release && \
    yum install -y \
    ccache \
    R-core-devel \
    R-Rcpp-devel \
    R-RInside-devel

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

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

# Base container image that builds all HPCC platform components

ARG BASE_VER=8.6 
ARG CR_USER=hpccsystems
ARG CR_REPO=docker.io
ARG CR_CONTAINER_NAME=platform-build-base
FROM ${CR_REPO}/${CR_USER}/${CR_CONTAINER_NAME}:${BASE_VER}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y dirmngr gnupg apt-transport-https ca-certificates software-properties-common

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN apt-add-repository 'deb https://download.mono-project.com/repo/ubuntu stable-focal main'
RUN apt-get install -y mono-complete 

WORKDIR /hpcc-dev/HPCC-Platform

ARG GITHUB_OWNER=hpcc-systems
ARG GITHUB_REF=hpcc-platform-8.8.x
RUN git clone -n https://github.com/${GITHUB_OWNER}/vcpkg.git

WORKDIR /hpcc-dev/HPCC-Platform/vcpkg
RUN git checkout ${GITHUB_REF}
RUN /hpcc-dev/HPCC-Platform/vcpkg/bootstrap-vcpkg.sh

ENV VCPKG_BINARY_SOURCES="clear;nuget,GitHub,readwrite"
ENV VCPKG_NUGET_REPOSITORY=https://github.com/hpcc-systems/vcpkg

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
RUN ./vcpkg install \
    --clean-after-build \
    --overlay-ports=./overlays || echo " *** vcpkg install failed ***"


#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

export $(grep -v '^#' $SCRIPT_DIR/../.env | xargs -d '\r' | xargs -d '\n')

GITHUB_BRANCH=$(git ls-remote https://github.com/hpcc-systems/vcpkg refs/heads/hpcc-platform-8.8.x | cut -f 1)
GITHUB_ACTOR="${GITHUB_ACTOR:-hpcc-systems}"
GITHUB_TOKEN="${GITHUB_TOKEN:-none}"

echo "$GITHUB_BRANCH"
echo "$GITHUB_ACTOR"
echo "$GITHUB_TOKEN"

docker build --progress plain --pull --rm -f "$SCRIPT_DIR/centos-7.dockerfile" -t vcpkg-centos-7:$GITHUB_BRANCH "$SCRIPT_DIR" \
    --build-arg BUILD_BRANCH=$GITHUB_BRANCH \
    --build-arg GITHUB_ACTOR=$GITHUB_ACTOR \
    --build-arg GITHUB_TOKEN=$GITHUB_TOKEN

docker build --progress plain --pull --rm -f "$SCRIPT_DIR/centos-8.dockerfile" -t vcpkg-centos-8:$GITHUB_BRANCH "$SCRIPT_DIR" \
    --build-arg BUILD_BRANCH=$GITHUB_BRANCH \
    --build-arg GITHUB_ACTOR=$GITHUB_ACTOR \
    --build-arg GITHUB_TOKEN=$GITHUB_TOKEN

docker build --progress plain --pull --rm -f "$SCRIPT_DIR/ubuntu-18.04.dockerfile" -t vcpkg-ubuntu-18.04:$GITHUB_BRANCH "$SCRIPT_DIR" \
    --build-arg BUILD_BRANCH=$GITHUB_BRANCH \
    --build-arg GITHUB_ACTOR=$GITHUB_ACTOR \
    --build-arg GITHUB_TOKEN=$GITHUB_TOKEN

docker build --progress plain --pull --rm -f "$SCRIPT_DIR/ubuntu-20.04.dockerfile" -t vcpkg-ubuntu-20.04:$GITHUB_BRANCH "$SCRIPT_DIR" \
    --build-arg BUILD_BRANCH=$GITHUB_BRANCH \
    --build-arg GITHUB_ACTOR=$GITHUB_ACTOR \
    --build-arg GITHUB_TOKEN=$GITHUB_TOKEN

docker build --progress plain --pull --rm -f "$SCRIPT_DIR/ubuntu-22.04.dockerfile" -t vcpkg-ubuntu-22.04:$GITHUB_BRANCH "$SCRIPT_DIR" \
    --build-arg BUILD_BRANCH=$GITHUB_BRANCH \
    --build-arg GITHUB_ACTOR=$GITHUB_ACTOR \
    --build-arg GITHUB_TOKEN=$GITHUB_TOKEN

#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

export $(grep -v '^#' $SCRIPT_DIR/../.env | xargs -d '\r' | xargs -d '\n')

GITHUB_OWNER="${GITHUB_OWNER:-hpcc-systems}"
GITHUB_BRANCH="${GITHUB_BRANCH:-hpcc-platform-8.8.x}"
GITHUB_REF=$(git ls-remote https://github.com/$GITHUB_OWNER/vcpkg refs/heads/$GITHUB_BRANCH | cut -f 1)
GITHUB_ACTOR="${GITHUB_ACTOR:-hpcc-systems}"
GITHUB_TOKEN="${GITHUB_TOKEN:-none}"

echo "$GITHUB_OWNER"
echo "$GITHUB_BRANCH"
echo "$GITHUB_REF"
echo "$GITHUB_ACTOR"
echo "$GITHUB_TOKEN"

docker build --progress plain --pull --rm -f "$SCRIPT_DIR/centos-7.dockerfile" -t vcpkg-centos-7:$GITHUB_REF "$SCRIPT_DIR" \
    --build-arg GITHUB_OWNER=$GITHUB_OWNER \
    --build-arg GITHUB_REF=$GITHUB_REF \
    --build-arg GITHUB_ACTOR=$GITHUB_ACTOR \
    --build-arg GITHUB_TOKEN=$GITHUB_TOKEN

docker build --progress plain --pull --rm -f "$SCRIPT_DIR/centos-8.dockerfile" -t vcpkg-centos-8:$GITHUB_REF "$SCRIPT_DIR" \
    --build-arg GITHUB_OWNER=$GITHUB_OWNER \
    --build-arg GITHUB_REF=$GITHUB_REF \
    --build-arg GITHUB_ACTOR=$GITHUB_ACTOR \
    --build-arg GITHUB_TOKEN=$GITHUB_TOKEN

docker build --progress plain --pull --rm -f "$SCRIPT_DIR/ubuntu-hpcc.dockerfile" -t vcpkg--ubuntu-hpcc:$GITHUB_REF "$SCRIPT_DIR" \
    --build-arg GITHUB_OWNER=$GITHUB_OWNER \
    --build-arg GITHUB_REF=$GITHUB_REF \
    --build-arg GITHUB_ACTOR=$GITHUB_ACTOR \
    --build-arg GITHUB_TOKEN=$GITHUB_TOKEN

docker build --progress plain --pull --rm -f "$SCRIPT_DIR/ubuntu-18.04.dockerfile" -t vcpkg-ubuntu-18.04:$GITHUB_REF "$SCRIPT_DIR" \
    --build-arg GITHUB_OWNER=$GITHUB_OWNER \
    --build-arg GITHUB_REF=$GITHUB_REF \
    --build-arg GITHUB_ACTOR=$GITHUB_ACTOR \
    --build-arg GITHUB_TOKEN=$GITHUB_TOKEN

docker build --progress plain --pull --rm -f "$SCRIPT_DIR/ubuntu-20.04.dockerfile" -t vcpkg-ubuntu-20.04:$GITHUB_REF "$SCRIPT_DIR" \
    --build-arg GITHUB_OWNER=$GITHUB_OWNER \
    --build-arg GITHUB_REF=$GITHUB_REF \
    --build-arg GITHUB_ACTOR=$GITHUB_ACTOR \
    --build-arg GITHUB_TOKEN=$GITHUB_TOKEN

docker build --progress plain --pull --rm -f "$SCRIPT_DIR/ubuntu-22.04.dockerfile" -t vcpkg-ubuntu-22.04:$GITHUB_REF "$SCRIPT_DIR" \
    --build-arg GITHUB_OWNER=$GITHUB_OWNER \
    --build-arg GITHUB_REF=$GITHUB_REF \
    --build-arg GITHUB_ACTOR=$GITHUB_ACTOR \
    --build-arg GITHUB_TOKEN=$GITHUB_TOKEN

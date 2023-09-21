#!/bin/bash
set -e

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

export $(grep -v '^#' $SCRIPT_DIR/../.env | xargs -d '\r' | xargs -d '\n') > /dev/null

GITHUB_ACTOR="${GITHUB_ACTOR:-hpcc-systems}"
GITHUB_TOKEN="${GITHUB_TOKEN:-none}"
GITHUB_REF=$(git rev-parse --short=8 HEAD)
GITHUB_BRANCH=$(git branch --show-current)
DOCKER_USERNAME="${DOCKER_USERNAME:-hpccbuilds}"
DOCKER_PASSWORD="${DOCKER_PASSWORD:-none}"

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "GITHUB_ACTOR: $GITHUB_ACTOR"
echo "GITHUB_TOKEN: $GITHUB_TOKEN"
echo "GITHUB_REF: $GITHUB_REF"
echo "GITHUB_BRANCH: $GITHUB_BRANCH"
echo "DOCKER_USERNAME: $DOCKER_USERNAME"
echo "DOCKER_PASSWORD: $DOCKER_PASSWORD"

docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD

function doBuild() {
    docker build --progress plain --rm -f "$SCRIPT_DIR/$1.dockerfile" \
        --build-arg NUGET_MODE=readwrite \
        --build-arg GITHUB_ACTOR=$GITHUB_ACTOR \
        --build-arg GITHUB_TOKEN=$GITHUB_TOKEN \
        -t hpccsystems/platform-build-base-$1:$GITHUB_REF \
        -t hpccsystems/platform-build-base-$1:$GITHUB_BRANCH \
        --cache-from hpccsystems/platform-build-base-$1:$GITHUB_REF \
        --cache-from hpccsystems/platform-build-base-$1:$GITHUB_BRANCH \
        "$SCRIPT_DIR/.."
    docker push hpccsystems/platform-build-base-$1:$GITHUB_REF
    docker push hpccsystems/platform-build-base-$1:$GITHUB_BRANCH
}

doBuild centos-7 &
doBuild centos-8 &
doBuild ubuntu-23.04 &
doBuild ubuntu-22.04 &
doBuild ubuntu-20.04 &
doBuild amazonlinux &

wait
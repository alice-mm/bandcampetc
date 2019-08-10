#! /usr/bin/env bash

readonly DOCKER_IMAGE_TAG=bandcampetc-integration-tests


# Get the name of the directory the current script sits in.
readonly SCR_DIR=$(
    dirname "$(readlink -f -- "$0")"
)

set -e

cd "${SCR_DIR:?}"

docker build -t "${DOCKER_IMAGE_TAG:?}" .

docker run --rm "${DOCKER_IMAGE_TAG:?}" /bc/it/run.sh

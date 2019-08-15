#! /usr/bin/env bash

readonly DOCKER_IMAGE_TAG=alice-mm/bandcampetc-it


# Get the name of the directory the current script sits in.
readonly SCR_DIR=$(
    dirname "$(readlink -f -- "$0")"
)

set -e

cd "${SCR_DIR:?}"

docker build -t "${DOCKER_IMAGE_TAG:?}" .

readonly TGRE=$(tput -T"${TERM:-xterm}" setaf 2 2> /dev/null)
readonly TRED=$(tput -T"${TERM:-xterm}" setaf 1 2> /dev/null)
readonly TNORM=$(tput -T"${TERM:-xterm}" sgr0 2> /dev/null)

if docker run --rm "${DOCKER_IMAGE_TAG:?}" /bc/it/run.sh
then
    echo
    printf "%s: Docker tests OK. ${TGRE}✓${TNORM}\n" "$(basename "$0")"
else
    status=$?
    
    echo
    printf "%s: Test failure. Docker status: %d ${TRED}❌${TNORM}\n" \
            "$(basename "$0")" "$status" >&2
fi

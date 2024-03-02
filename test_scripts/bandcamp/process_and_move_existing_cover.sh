#! /usr/bin/env bash

set -ex

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


# Turn image-processing stuff into simple copies.
# We will be able to check for the presence of target files.
function convert { cp -- "$@"; }
LQCOVER=mock_lqcover
function mock_lqcover { cp -- "$1" "$(dirname "$1")"/"$2"; }

COVER_LQ_BASENAME=lsilsi

tdir=$(mktemp -d "${TMPDIR:-/tmp}"/bandcamp-cover-test-XXXXXXXX)

cd "${tdir:?}"

if ( process_and_move_existing_cover; true )
then
    : Should have failed
    exit 1
fi

: Basic case.
mkdir -p storage/{mp3,flac} some/random/location
touch some/random/location/cover.jpg

process_and_move_existing_cover some/random/location/cover.jpg

test -r storage/mp3/cover.jpg
test -r storage/mp3/lsilsi
test -r storage/flac/cover.jpg
test -r storage/flac/lsilsi
test ! -e some/random/location/cover.jpg
test ! -e some/random/location/lsilsi

rm -r "${tdir:?}"/*


: With a GIF: need conversion.
mkdir -p storage/{mp3,flac} some/random/location
touch some/random/location/cover.gif

process_and_move_existing_cover some/random/location/cover.gif

test -r storage/mp3/cover.jpg
test -r storage/mp3/lsilsi
test ! -e storage/mp3/cover.gif
test -r storage/flac/cover.jpg
test -r storage/flac/lsilsi
test ! -e storage/flac/cover.gif
test ! -e some/random/location/cover.gif
test ! -e some/random/location/cover.jpg
test ! -e some/random/location/lsilsi

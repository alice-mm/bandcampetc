#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


! ( apply_cover_if_we_got_one; true )

COVER_LQ_BASENAME=poire
SETCOVER=mock_setcover

function mock_setcover {
    ((_called++)) || true
    
    # Save arguments for check later.
    # 1) Clear “_args<n>” variable.
    unset -v "_args${_called}"
    # 2) Declare a global “_args<n>” indexed array.
    declare -ag "_args${_called}"
    # 3) Use a local handle to write in the “_args<n>” array.
    local -n ref=_args${_called}
    # 4) Fill it with this call’s arguments.
    ref=("$@")
}

_called=0
apply_cover_if_we_got_one mp3
test "$_called" -eq 0

_called=0
apply_cover_if_we_got_one flac
test "$_called" -eq 0

tdir=$(mktemp -d "${TMPDIR:-/tmp}"/bandcamp-apply-test-XXXXXXXX)
cd "${tdir:?}"

mkdir -p storage/{mp3,flac}/
touch storage/{mp3,flac}/poire

_called=0
apply_cover_if_we_got_one mp3
test "$_called" -eq 1
test "${_args1[*]}" = 'storage/mp3/ storage/mp3/poire'

_called=0
apply_cover_if_we_got_one flac
test "$_called" -eq 1
test "${_args1[*]}" = 'storage/flac/ storage/flac/poire'

CONVERT_TO_MP3=1

_called=0
apply_cover_if_we_got_one flac
test "$_called" -eq 2
test "${_args1[*]}" = 'storage/flac/ storage/flac/poire'
test "${_args2[*]}" = 'storage/mp3/ storage/flac/poire'

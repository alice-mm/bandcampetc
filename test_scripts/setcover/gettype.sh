#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/setcover_functions.sh
. lib/setcover_functions.sh


# Mock the “file” command to return mime types
# for non existing files.
function file {
    printf '%s\n' "$_mime"
}

# Normal cases.
_mime=audio/mpeg
test "$(f_gettype foo.mp3)" = mp3

_mime=application/octet-stream
test "$(f_gettype foo.mp3)" = mp3

_mime=audio/x-flac
test "$(f_gettype foo.flac)" = flac

_mime=audio/mpeg
test "$(f_gettype FOO.MP3)" = mp3

_mime=application/octet-stream
test "$(f_gettype FOO.MP3)" = mp3

_mime=audio/x-flac
test "$(f_gettype FOO.FLAC)" = flac

# Unknown types.
_mime=zblork/lrilrilri
test -z "$(f_gettype foo.mp3)"
test -z "$(f_gettype foo.flac)"
test -z "$(f_gettype FOO.MP3)"
test -z "$(f_gettype FOO.FLAC)"

_mime=audio/mpeg
test -z "$(f_gettype foo.flac)"

_mime=application/octet-stream
test -z "$(f_gettype foo.flac)"

_mime=audio/x-flac
test -z "$(f_gettype foo.mp3)"

_mime=audio/mpeg
test -z "$(f_gettype FOO.FLAC)"

_mime=application/octet-stream
test -z "$(f_gettype FOO.FLAC)"

_mime=audio/x-flac
test -z "$(f_gettype FOO.MP3)"

_mime=audio/mpeg
test -z "$(f_gettype foo.cpp)"

_mime=application/octet-stream
test -z "$(f_gettype foo.cpp)"

_mime=audio/x-flac
test -z "$(f_gettype foo.cpp)"

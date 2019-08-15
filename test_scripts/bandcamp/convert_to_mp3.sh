#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


function mock_conv {
    _called=1
    
    local -a expected_args=(
        -v      quiet
        -i      src.flac
        -acodec libmp3lame
        -ab     154k
        dest.mp3 
    )
    
    # Compare array. A bit sloppy, but let’s assume
    # the args do not contain pipes themselves.
    if ( IFS='|'; [ "$*" = "${expected_args[*]}" ] )
    then
        _ok=1
    fi
    
    return "$_status"
}

CONV=mock_conv

_status=0

CONVERTED_MP3_RATE=154k

# Should exit the subshell because of missing args.
# The “true” should therefore not be executed.
( convert_to_mp3;           true ) && exit 1
( convert_to_mp3 foo;       true ) && exit 1
( convert_to_mp3 '' bar;    true ) && exit 1

unset -v _called _ok
convert_to_mp3 src.flac dest.mp3
test "$_called"
test "$_ok"

_status=1

unset -v _called _ok
! convert_to_mp3 src.flac dest.mp3
test "$_called"
test "$_ok"

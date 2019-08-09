#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


function mock_mmeta {
    if [ "$1" != '%T' ]
    then
        return 1
    fi
    
    case "$2" in
        storage/mp3/foo.mp3)    echo 6;;
        storage/flac/foo.flac)  echo 8;;
        *) return 1;;
    esac
}

MMETA=mock_mmeta

! ( process_one_source_file;            true )
! ( process_one_source_file a;          true )
! ( process_one_source_file a b;        true )
! ( process_one_source_file '' b c;     true )
! ( process_one_source_file a '' c;     true )
! ( process_one_source_file '' '' c;    true )

unset -v meta
declare -A meta=(
    [artist]='a b'
    [album]='C d Ef'
    [maxtrack]=98
    [genre]=Genre
    [year]=1899
)

unset -v tracks
declare -a tracks=(
    [6]='The title of track six'
    [8]='The title of track eight'
)

unset -v _mp3_tag_expectations
_mp3_tag_expectations=(
    storage/mp3/foo.mp3
    6
    'The title of track six'
    meta
)

function retag_mp3 {
    _called_tag_mp3=1
    
    if (
        IFS=','
        test "$*" = "${_mp3_tag_expectations[*]}"
    )
    then
        _tagged_mp3=1
    fi
}

function retag_flac {
    _called_tag_flac=1
    
    if (
        IFS=','
        test "$*" = storage/flac/foo.flac,8,'The title of track eight',meta
    )
    then
        _tagged_flac=1
    fi
}

unset -v _tagged_mp3 _tagged_flac _called_tag_mp3 _called_tag_flac
process_one_source_file storage/mp3/foo.mp3 meta tracks
test "$_called_tag_mp3"
test "$_tagged_mp3"
test ! "$_called_tag_flac"
test ! "$_tagged_flac"
test ! "$_mkdir_ok"
test ! "$_convert_ok"

unset -v _tagged_mp3 _tagged_flac _called_tag_mp3 _called_tag_flac
process_one_source_file storage/flac/foo.flac meta tracks
test ! "$_called_tag_mp3"
test ! "$_tagged_mp3"
test "$_called_tag_flac"
test "$_tagged_flac"
test ! "$_mkdir_ok"
test ! "$_convert_ok"

CONVERT_TO_MP3=1

function mkdir {
    if (
        IFS=','
        [ $# -eq 2 ] &&
        [ "$*" = -p,storage/mp3/ ]
    )
    then
        _mkdir_ok=1
    fi
}

function convert_to_mp3 {
    if (
        IFS=','
        test $# -eq 2 &&
        test "$*" = storage/flac/foo.flac,storage/mp3/foo.mp3
    )
    then
        _convert_ok=1
    fi
}

# Here, the expectations must match the metadata of the FLAC file
# since this MP3 is just a converted version of it
# and not a track of its own.
_mp3_tag_expectations=(
    storage/mp3/foo.mp3
    8
    'The title of track eight'
    meta
)

unset -v _tagged_mp3 _tagged_flac _called_tag_mp3 _called_tag_flac
unset -v _mkdir_ok _convert_ok

process_one_source_file storage/flac/foo.flac meta tracks

test "$_called_tag_mp3"
test "$_tagged_mp3"
test "$_called_tag_flac"
test "$_tagged_flac"
test "$_mkdir_ok"
test "$_convert_ok"

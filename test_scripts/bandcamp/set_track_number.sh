#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


! ( set_track_number_for_mp3;           true )
! ( set_track_number_for_mp3 foo;       true )
! ( set_track_number_for_mp3 '' bar;    true )

unset -v _calls
declare -a _calls

function eyeD3 {
    _calls+=("$*")
}

set_track_number_for_mp3 foo/bar.mp3 42
test ${#_calls[@]} -eq 1
test "${_calls[0]}" = '--to-v2.4 --no-color --no-tagging-time-frame --track=42 foo/bar.mp3'

# Should fail if tagging fails.
function eyeD3 { false; }
! set_track_number_for_mp3 foo/bar.mp3 42


: MP3 ↑ / ↓ FLAC


! ( set_track_number_for_flac;          true )
! ( set_track_number_for_flac foo;      true )
! ( set_track_number_for_flac '' bar;   true )

unset -v _calls
declare -a _calls

function metaflac {
    _calls+=("$*")
}

set_track_number_for_flac foo/bar.flac 42
test ${#_calls[@]} -eq 1
test "${_calls[0]}" = '--dont-use-padding --remove-tag=TRACKNUMBER --set-tag=TRACKNUMBER=42 foo/bar.flac'

# Should fail if tagging fails.
function metaflac { false; }
! set_track_number_for_flac foo/bar.flac 42


: Generic function.

function set_track_number_for_mp3   {
    if [ "$1" = "$path" ] && [ "$2" = 42 ]
    then
        _called_mp3=1
    fi
}
function set_track_number_for_flac  {
    if [ "$1" = "$path" ] && [ "$2" = 42 ]
    then
        _called_flac=1
    fi
}

for path in foo.mp3 FOO.MP3 foo/bar.mp3 ./a/B/c/D/plop.Mp3
do
    unset -v _called_mp3 _called_flac
    set_track_number_for_file "$path" 42
    test "$_called_mp3"
    test -z "$_called_flac"
done

for path in foo.flac FOO.FLAC foo/bar.flac ./a/B/c/D/plop.FlAc
do
    unset -v _called_mp3 _called_flac
    set_track_number_for_file "$path" 42
    test -z "$_called_mp3"
    test "$_called_flac"
done

: Wrong types.
for path in lsilsi lsi.txt FOO.PDF ./././.
do
    unset -v _called_mp3 _called_flac
    ! set_track_number_for_file "$path" 42
    test -z "$_called_mp3"
    test -z "$_called_flac"
done

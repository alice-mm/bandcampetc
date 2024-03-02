#! /usr/bin/env bash

set -ex

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


if ( set_track_number_for_mp3;           true )
then
    : Should have failed
    exit 1
fi
if ( set_track_number_for_mp3 foo;       true )
then
    : Should have failed
    exit 1
fi
if ( set_track_number_for_mp3 '' bar;    true )
then
    : Should have failed
    exit 1
fi

unset -v _calls
declare -a _calls

function eyeD3 {
    _calls+=("$*")
}

set_track_number_for_mp3 foo/bar.mp3 42
test ${#_calls[@]} -eq 1
test "${_calls[0]}" = '--to-v2.4 --no-color --track=42 foo/bar.mp3'

# Should fail if tagging fails.
function eyeD3 { false; }
if set_track_number_for_mp3 foo/bar.mp3 42
then
    : Should have failed
    exit 1
fi


: MP3 ↑ / ↓ FLAC


if ( set_track_number_for_flac;          true )
then
    : Should have failed
    exit 1
fi
if ( set_track_number_for_flac foo;      true )
then
    : Should have failed
    exit 1
fi
if ( set_track_number_for_flac '' bar;   true )
then
    : Should have failed
    exit 1
fi

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
if set_track_number_for_flac foo/bar.flac 42
then
    : Should have failed
    exit 1
fi


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
    if set_track_number_for_file "$path" 42
    then
        : Should have failed
        exit 1
    fi
    test -z "$_called_mp3"
    test -z "$_called_flac"
done

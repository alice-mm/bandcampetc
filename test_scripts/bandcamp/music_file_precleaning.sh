#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


! ( music_file_precleaning; true )

tdir=$(mktemp -d "${TMPDIR:-/tmp}"/bandcamp-test-preclean-XXXXXXXX)
cd "${tdir:?}"

mkdir -p storage/mp3/

: Call with no file just to see if something goes wrong.
music_file_precleaning mp3

touch storage/mp3/{1_foo,2_bar,3_plop,4_plup,5_yo}.mp3

function set_track_number_for_file {
    _set_calls+=("${2} ${1}")
}

function get_clean_track_number_from_file {
    local id
    
    id=$(basename "${1:?}")
    id=${id%.mp3}
    
    case "$id" in
        1_foo)  echo 0;;
        2_bar)  echo 3;;
        3_plop) echo 8;;
        4_plup) echo 0;;
        5_yo)   echo 3;;
        
        *) exit 1;;
    esac
}

unset -v _set_calls
declare -a _set_calls
music_file_precleaning mp3
test ${#_set_calls[@]} -eq 3
test "${_set_calls[0]}" = '1 storage/mp3/1_foo.mp3'
test "${_set_calls[1]}" = '2 storage/mp3/4_plup.mp3'
test "${_set_calls[2]}" = '4 storage/mp3/5_yo.mp3'

function get_clean_track_number_from_file {
    local id
    
    id=$(basename "${1:?}")
    id=${id%.mp3}
    
    case "$id" in
        1_foo)  echo 1;;
        2_bar)  echo 1;;
        3_plop) echo 1;;
        4_plup) echo 1;;
        5_yo)   echo 1;;
        
        *) exit 1;;
    esac
}

unset -v _set_calls
declare -a _set_calls
music_file_precleaning mp3
test ${#_set_calls[@]} -eq 4
test "${_set_calls[0]}" = '2 storage/mp3/2_bar.mp3'
test "${_set_calls[1]}" = '3 storage/mp3/3_plop.mp3'
test "${_set_calls[2]}" = '4 storage/mp3/4_plup.mp3'
test "${_set_calls[3]}" = '5 storage/mp3/5_yo.mp3'

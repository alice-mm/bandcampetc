#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


! ( init_metadata;          true )
! ( init_metadata foo;      true )
! ( init_metadata '' bar;   true )

# Set args, but file not found.
! init_metadata foo bar

tempf=$(mktemp "${TMPDIR:-/tmp}"/bandcamp-init-test-XXXXXXXX)
test "$tempf"
test -r "$tempf"


_mock_mmeta_genre='Some genre'

function mock_mmeta {
    case "$1" in
        %a) printf 'a r t ist';;
        %A) printf 'alb (UM)';;
        '-e')
            if [ "$2" = '%y' ]
            then
                printf 2016
            fi
            ;;
        %g) printf '%s' "$_mock_mmeta_genre";;
        *) return 1;;
    esac
}

MMETA=mock_mmeta

# Get the name of the directory the current script sits in.
readonly SCR_DIR=$(dirname "$(readlink -f -- "$0")")
CAPITASONG=${SCR_DIR}/../../bin/capitasong


init_metadata "$tempf" meta

test "${meta[artist]}"      = 'A R T Ist'
test "${meta[albumartist]}" = 'A R T Ist'
test "${meta[album]}"       = 'Alb (UM)'
test "${meta[year]}"        = 2016
test "${meta[genre]}"       = 'Some genre'

# Force the use of the fallback function to find a genre.
MMETA_PLACEHOLDER='????'
_mock_mmeta_genre='????'
function try_to_guess_genre {
    if [ "$1" = 'A R T Ist' ]
    then
        echo jrijrijri
    fi
}

init_metadata "$tempf" meta

test "${meta[artist]}"      = 'A R T Ist'
test "${meta[albumartist]}" = 'A R T Ist'
test "${meta[album]}"       = 'Alb (UM)'
test "${meta[year]}"        = 2016
test "${meta[genre]}"       = jrijrijri

# Force the use of the fallback function,
# but make it fail, too.
MMETA_PLACEHOLDER='????'
_mock_mmeta_genre='????'

tempf_callcheck=$(mktemp "${TMPDIR:-/tmp}"/bandcamp-init-test-callcheck-XXXXXXXX)
test "$tempf_callcheck"
test -r "$tempf_callcheck"

# Need to use a file because called in a subshell (no way
# to set a variable and get the value from the test script).
function try_to_guess_genre {
    echo CALLED >> "$tempf_callcheck"
}

init_metadata "$tempf" meta
test "$(cat "$tempf_callcheck")" = CALLED

test "${meta[artist]}"      = 'A R T Ist'
test "${meta[albumartist]}" = 'A R T Ist'
test "${meta[album]}"       = 'Alb (UM)'
test "${meta[year]}"        = 2016
test "${meta[genre]}"       = '????'

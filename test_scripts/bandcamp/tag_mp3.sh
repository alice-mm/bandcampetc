#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


unset -v EYED3_ENCODING_OPT
EYED3_ENCODING_OPT=(foo bar plop)


callfile=$(mktemp "${TMPDIR:-/tmp}"/bandcamp-test-tag-mp3-XXXXXXXX)
test "$callfile"
test -r "$callfile"
test -w "$callfile"


function eyeD3 {
    echo called > "$callfile"
    
    local -a expected_args=(
        --no-color
        --remove-all
        "${EYED3_ENCODING_OPT[@]}"
        
        --artist="$_expected_artist"
        --album='C d Ef'
        --title='lsilsi jrejre'
        --track=42
        --track-total=98
        --genre=Genre
        -Y 1899
        
        dest.mp3
    )
    
    # Compare array. A bit sloppy, but let’s assume
    # the args do not contain pipes themselves.
    if ( IFS='|'; [ "$*" = "${expected_args[*]}" ] )
    then
        echo ok > "$callfile"
    fi
    
    return "$_status"
}

_status=0

# Should exit the subshell because of missing args.
# The “true” should therefore not be executed.
! ( retag_mp3;                  true )
! ( retag_mp3 foo;              true )
! ( retag_mp3 '' bar;           true )
! ( retag_mp3 foo bar plop;     true )
! ( retag_mp3 foo bar plop '';  true )

unset -v meta
declare -A meta=(
    [artist]='a b'
    [album]='C d Ef'
    [maxtrack]=98
    [genre]=Genre
    [year]=1899
)

> "$callfile"
_expected_artist='a b'
retag_mp3 dest.mp3 42 'lsilsi jrejre' meta
test "$(cat "$callfile")" = ok

_status=1

> "$callfile"
_expected_artist='a b'
! retag_mp3 dest.mp3 42 'lsilsi jrejre' meta
test "$(cat "$callfile")" = ok

: With custom artist.
_status=0
> "$callfile"
meta['a42']='Cus Tom'
_expected_artist='Cus Tom'
retag_mp3 dest.mp3 42 'lsilsi jrejre' meta
test "$(cat "$callfile")" = ok


: Setup to stop expecting dates because I will give invalid ones.
function eyeD3 {
    echo called > "$callfile"
    
    local -a expected_args=(
        --no-color
        --remove-all
        "${EYED3_ENCODING_OPT[@]}"
        
        --artist="$_expected_artist"
        --album='C d Ef'
        --title='lsilsi jrejre'
        --track=42
        --track-total=98
        --genre=Genre
        
        dest.mp3
    )
    
    # Compare array. A bit sloppy, but let’s assume
    # the args do not contain pipes themselves.
    if ( IFS='|'; [ "$*" = "${expected_args[*]}" ] )
    then
        echo ok > "$callfile"
    fi
    
    return "$_status"
}

unset -v meta
declare -A meta=(
    [artist]='a b'
    [album]='C d Ef'
    [maxtrack]=98
    [genre]=Genre
    [year]='Grosse poire'
)

_status=0

> "$callfile"
_expected_artist='a b'
retag_mp3 dest.mp3 42 'lsilsi jrejre' meta
test "$(cat "$callfile")" = ok

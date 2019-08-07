#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


function eyeD3 {
    _called=1
    
    local -a expected_args=(
        --no-color
        --remove-all
        --no-tagging-time-frame
        --set-encoding=utf8
        
        --artist='a b'
        --album='C d Ef'
        --title='lsilsi jrejre'
        --track=42
        --track-total=98
        --genre=Genre
        --year=1899
        
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

unset -v _called _ok
retag_mp3 dest.mp3 42 'lsilsi jrejre' meta
test "$_called"
test "$_ok"

_status=1

unset -v _called _ok
! retag_mp3 dest.mp3 42 'lsilsi jrejre' meta
test "$_called"
test "$_ok"

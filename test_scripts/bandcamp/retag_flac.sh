#! /usr/bin/env bash

set -evx

. lib/bandcamp_functions.sh


# Mock + check.
function metaflac {
    # “--dont-use-padding” + 6 tags to rm and add back + file.
    test $# -eq $((2 + 6 * 2))
    
    test "$1" = --dont-use-padding
    
    test "$2" = --remove-tag=TITLE
    test "$3" = --remove-tag=ARTIST
    test "$4" = --remove-tag=ALBUMARTIST
    test "$5" = --remove-tag=ALBUM
    test "$6" = --remove-tag=GENRE
    test "$7" = --remove-tag=DATE
    
    test "$8"       = --set-tag=TITLE='foo bar'
    test "$9"       = --set-tag=ARTIST='a r t i s t'
    test "${10}"    = --set-tag=ALBUMARTIST='alb ar'
    test "${11}"    = --set-tag=ALBUM='bu bu BUM'
    test "${12}"    = --set-tag=GENRE='Esoteric genre'
    test "${13}"    = --set-tag=DATE=1324
    
    test "${14}" = foo.flac
}

unset -v tags
declare -A tags

tags[artist]='a r t i s t'
tags[albumartist]='alb ar'
tags[album]='bu bu BUM'
tags[genre]='Esoteric genre'
tags[year]=1324

retag_flac foo.flac 'foo bar' tags

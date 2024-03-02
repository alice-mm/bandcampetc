#! /usr/bin/env bash

set -ex

# shellcheck source=../../lib/bandcamp_functions.sh
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
    test "$9"       = --set-tag=ARTIST="$_expected_artist"
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

_expected_artist='a r t i s t'
retag_flac foo.flac 12 'foo bar' tags


: With custom artist.

unset -v tags
declare -A tags

tags[artist]='a r t i s t'
tags[albumartist]='alb ar'
tags[album]='bu bu BUM'
tags[genre]='Esoteric genre'
tags[year]=1324
tags[a12]='Cus Tom'

_expected_artist='Cus Tom'
retag_flac foo.flac 12 'foo bar' tags

: Setup to stop expecting dates because I will give invalid ones.
function metaflac {
    # “--dont-use-padding” + 6 tags to rm and add back + file.
    # “-1” because no date setting.
    test $# -eq $((2 + 6 * 2 - 1))
    
    test "$1" = --dont-use-padding
    
    test "$2" = --remove-tag=TITLE
    test "$3" = --remove-tag=ARTIST
    test "$4" = --remove-tag=ALBUMARTIST
    test "$5" = --remove-tag=ALBUM
    test "$6" = --remove-tag=GENRE
    test "$7" = --remove-tag=DATE
    
    test "$8"       = --set-tag=TITLE='foo bar'
    test "$9"       = --set-tag=ARTIST="$_expected_artist"
    test "${10}"    = --set-tag=ALBUMARTIST='alb ar'
    test "${11}"    = --set-tag=ALBUM='bu bu BUM'
    test "${12}"    = --set-tag=GENRE='Esoteric genre'
    
    test "${13}" = foo.flac
}

unset -v tags
declare -A tags

tags[artist]='a r t i s t'
tags[albumartist]='alb ar'
tags[album]='bu bu BUM'
tags[genre]='Esoteric genre'
tags[year]='Grosse poire'
tags[a12]='Cus Tom'

_expected_artist='Cus Tom'
retag_flac foo.flac 12 'foo bar' tags

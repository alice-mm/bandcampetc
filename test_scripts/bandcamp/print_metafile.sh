#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


function mock_mmeta {
    case "$# $*" in
        '2 %T\n '*)
            echo 03/009
            ;;
        
        '3 -e %t '*)
            echo 'a a b a a'
            ;;
        
        *)
            exit 1
            ;;
    esac
}

MMETA=mock_mmeta
CAPITASONG=bin/capitasong

test "$(print_metafile_line_for_track foo)" = '3      = A a B a A'

function find {
    printf 'foo\0'
    printf 'bar\0'
}

unset -v meta
declare -A meta
meta=(
    [artist]='lsi lsi lsi'
    [albumartist]='lsi uyuyu lsi'
    [album]='lsi dldldl lsi'
    [year]=1998
    [genre]='lsi nrnrnr lsi'
)

test "$(print_metafile_content osef meta)" = "$(

    cat << '_EXPECTED_'
# Edit this file, save, and close your editor.
# If this ZIP was not meant to be read,
# set “SKIP” to “y” to skip it.

SKIP        = n

# Most albums will have ARTIST=ALBUMARTIST, but for collaborations
# and featurings, typically, you’d put only the “main” artist (or
# “Various artists”, for example in video game soundtracks)
# in “ALBUMARTIST” while writing every name in “ARTIST”.
# Note that the ARTIST can be overridden for specific tracks
# (see below), while ALBUMARTIST will be applied as-is to all tracks,
# in order to keep the sorting straight within music players, and
# this will be the value used to name the artist directory
# when saving the final files.
# Example: ALBUMARTIST=Converge // ARTIST=Converge & Chelsea Wolfe
ARTIST      = lsi lsi lsi
ALBUMARTIST = lsi uyuyu lsi
ALBUM       = lsi dldldl lsi
YEAR        = 1998
GENRE       = lsi nrnrnr lsi

# <Track #> = <Title>
3      = A a B a A
3      = A a B a A

# If some tracks should have a different artist
# than ARTIST, you can add a line to override it.
# For example, to set “Some Guy” as artist for
# the 7th track, add (anywhere) a line like:
#
#       a7=Some guy
#
# (without the “#”)
# You can also set the same custom artist for
# several tracks in one line, using a list of
# track numbers and (optionally) intervals:
#
#       a3,5-8,13 = Another Artist
#
# This will set the artist for tracks 3, 5,
# 6, 7, 8 and 13.
_EXPECTED_
)"


function mock_mmeta {
    case "$# $*" in
        '2 %T\n '*)
            echo 03/009
            ;;
        
        '3 -e %t '*)
            # No title available, say nothing.
            ;;
        
        *)
            exit 1
            ;;
    esac
}

test "$(print_metafile_line_for_track 'foo bar')" = '3      = Foo Bar'

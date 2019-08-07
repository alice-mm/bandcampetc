#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


function mock_mmeta {
    case "$1" in
        '%T\n')
            echo 03/009
            ;;
        
        '%t')
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

ARTIST      = lsi lsi lsi
ALBUMARTIST = lsi uyuyu lsi
ALBUM       = lsi dldldl lsi
YEAR        = 1998
GENRE       = lsi nrnrnr lsi

# <Track #> = <Title>
3      = A a B a A
3      = A a B a A
_EXPECTED_
)"
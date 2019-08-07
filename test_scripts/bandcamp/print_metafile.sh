#! /usr/bin/env bash

set -evx

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

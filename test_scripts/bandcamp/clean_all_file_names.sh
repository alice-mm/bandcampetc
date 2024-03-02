#! /usr/bin/env bash

set -ex

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


function mock_mmeta {
    case "$1" in
        '%T')
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

# Get the name of the directory the current script sits in.
readonly SCR_DIR=$(
    dirname "$(readlink -f -- "$0")"
)
RENAME=${SCR_DIR}/../../bin/to_acceptable_name

tdir=$(mktemp -d "${TMPDIR:-/tmp}"/bandcamp-clean-test-XXXXXXXX)

cd "${tdir:?}"

if ( clean_all_file_names; true )
then
    : Should have failed
    exit 1
fi

mkdir -p storage/{foo,bar,plop}/
touch storage/foo/'jRæŸ=r (foo1) bar'.flac
touch storage/foo/'jRæŸ=r (foo2) bar'
touch storage/bar/'jRæŸ=r (foo3) bar'.MP3
touch storage/plop/'jRæŸ=r (foo4) bar'
touch storage/plop/'jRæŸ=r (foo5) bar'.pdf

unset -v meta
declare -A meta=( [maxtrack]=109 )

clean_all_file_names meta

test "$(find . -type f | sort)" = "$(
    cat << '_EXPECTATIONS_'
./storage/bar/003_-_a_a_b_a_a.mp3
./storage/foo/003_-_a_a_b_a_a.flac
./storage/foo/jraey_r_foo2_bar
./storage/plop/jraey_r_foo4_bar
./storage/plop/jraey_r_foo5_bar.pdf
_EXPECTATIONS_
)"

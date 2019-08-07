#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


tdir=$(mktemp -d "${TMPDIR:-/tmp}"/bandcamp-test-XXXXXXXX)

cd "${tdir:?}"

: Empty dir.
sample=$(get_sample_file)
test -z "$sample"
test -z "$(get_record_format "$sample")"

: Irrelevant files.
touch foo.txt bar.gif PLOP.PNG POIRE.JPG .mp3 .flac .MP3 .FLAC
sample=$(get_sample_file)
test -z "$sample"
test -z "$(get_record_format "$sample")"

: MP3.
touch nya.mp3
sample=$(get_sample_file)
test "$sample" = ./nya.mp3
test "$(get_record_format "$sample")" = mp3
rm nya.mp3
touch NYA.MP3
sample=$(get_sample_file)
test "$sample" = ./NYA.MP3
test "$(get_record_format "$sample")" = mp3
rm NYA.MP3

: FLAC.
touch nya.flac
sample=$(get_sample_file)
test "$sample" = ./nya.flac
test "$(get_record_format "$sample")" = flac
rm nya.flac
touch NYA.FLAC
sample=$(get_sample_file)
test "$sample" = ./NYA.FLAC
test "$(get_record_format "$sample")" = flac
rm NYA.FLAC

: Both.
touch nya.mp3 nya.flac
sample=$(get_sample_file)
test "$sample" = ./nya.mp3 || test "$sample" = ./nya.flac
res=$(get_record_format "$sample")
test "$res" = mp3 || test "$res" = flac

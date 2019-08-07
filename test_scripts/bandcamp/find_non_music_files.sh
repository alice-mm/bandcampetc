#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


tdir=$(mktemp -d "${TMPDIR:-/tmp}"/bandcamp-find-test-XXXXXXXX)

cd "${tdir:?}"

COVER_LQ_BASENAME=poire

unset -v still_needs_to_be_found
declare -A still_needs_to_be_found=(
    [foo.txt]=1
    [BAR.PDF]=1
    [jrijri.md]=1
    [indir.pdf]=1
    [a.jpg]=1
    [b.jpeg]=1
    [c.png]=1
    [d.gif]=1
)

unset -v to_create
to_create=(
    poire
    cover.jpg
    cover.jpeg
    cover.png
    cover.gif
    COVER.JPG
    COVER.JPEG
    COVER.PNG
    COVER.GIF
    
    foo.txt BAR.PDF jrijri.md
    a.jpg b.jpeg c.png d.gif
    
    osef.mp3 nope.flac OSEF.MP3 NOPE.FLAC
)

touch "${to_create[@]}"
# We also need to check that directories
# are scanned for content as well.
mkdir somedir/
touch somedir/indir.pdf

while read -rd '' one_file
do
    one_file=$(basename "$one_file")
    : File: "$one_file"
    
    : Make sure we needed to find that file.
    test "${still_needs_to_be_found[$one_file]}"
    : Remove it from the set of “stuff left to find”.
    unset -v still_needs_to_be_found[$one_file]
done < <(find_non_music_files)

test ${#still_needs_to_be_found[@]} -eq 0

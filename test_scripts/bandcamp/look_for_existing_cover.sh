#! /usr/bin/env bash

set -ex

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


tdir=$(mktemp -d "${TMPDIR:-/tmp}"/bandcamp-cover-test-XXXXXXXX)

cd "${tdir:?}"

sta=0
out=$(look_for_existing_cover) || sta=$?
test -z "$out"
test "$sta" -eq 1

unset -v ok not_ok
ok=(
    cover.jpg
    COVER.JPG
    cover.JPG
    COVER.jpg
    
    cover.jpeg
    COVER.JPEG
    cover.JPEG
    COVER.jpeg
    
    cover.png
    COVER.PNG
    cover.PNG
    COVER.png
    
    cover.gif
    COVER.GIF
    cover.GIF
    COVER.gif
    
    cOvEr.jpg
)
not_ok=(
    foo.jpg
    foo.JPG
    foo.png
    .jpg
    .png
)

for name in "${ok[@]}"
do
    touch -- "${name:?}"
    
    sta=0
    out=$(look_for_existing_cover) || sta=$?
    test "$out" = ./"$name"
    test "$sta" -eq 0
    
    rm -- "${name:?}"
done

for name in "${not_ok[@]}"
do
    touch -- "${name:?}"
    
    sta=0
    out=$(look_for_existing_cover) || sta=$?
    test -z "$out"
    test "$sta" -eq 1
    
    rm -- "${name:?}"
done

# Cover within a directory.
mkdir -p some/dir/
touch some/dir/cover.jpg

sta=0
out=$(look_for_existing_cover) || sta=$?
test "$out" = ./some/dir/cover.jpg
test "$sta" -eq 0

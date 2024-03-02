#! /usr/bin/env bash

set -ex

# shellcheck source=../../lib/setcover_functions.sh
. lib/setcover_functions.sh


callfile=$(mktemp "${TMPDIR:-/tmp}"/setcover-test-tag-flac-XXXXXXXX)
test "$callfile"
test -r "$callfile"


function metaflac {
    if [ $# -eq 4 ] && [ "$*" = '--list --block-type PICTURE foo.flac' ]
    then
        printf '%s\n' "$_list"
    else
        {
            printf 'metaflac'
            printf ' %q' "$@"
            echo
        } >> "$callfile"
    fi
}


if ( f_tag_flac;         true )
then
    : Should have failed
    exit 1
fi
if ( f_tag_flac '';      true )
then
    : Should have failed
    exit 1
fi
if ( f_tag_flac '' '';   true )
then
    : Should have failed
    exit 1
fi
if ( f_tag_flac '' foo;  true )
then
    : Should have failed
    exit 1
fi


_list=$(
    cat << '_DATA_'
METADATA block #3
  type: 6 (PICTURE)
  is last: false
  length: 170210
  type: 3 (Cover (front))
  MIME type: image/jpeg
  description: 
  width: 512
  height: 512
  depth: 24
  colors: 0 (unindexed)
  data length: 170168
  data:
    00000000: FF D8 FF E0 00 10 4A 46 49 46 00 01 01 01 00 48 ......JFIF.....H
    00000010: 00 48 00 00 FF ED 38 84 50 68 6F 74 6F 73 68 6F .H....8.Photosho
METADATA block #6
  type: 6 (PICTURE)
  is last: true
  length: 10774
  type: 3 (Cover (front))
  MIME type: image/png
  description: 
  width: 1015
  height: 618
  depth: 24
  colors: 16
  data length: 10733
  data:
    00000000: 89 50 4E 47 0D 0A 1A 0A 00 00 00 0D 49 48 44 52 .PNG........IHDR
    00000010: 00 00 03 F7 00 00 02 6A 04 03 00 00 00 9C 27 AD .......j......o.
_DATA_
)

> "$callfile"
f_tag_flac foo.flac ''
test "$(cat "$callfile")" = 'metaflac --dont-use-padding --remove --block-number=3\,6 foo.flac'

> "$callfile"
f_tag_flac foo.flac wololo.jpg
test "$(cat "$callfile")" = 'metaflac --dont-use-padding --remove --block-number=3\,6 foo.flac
metaflac --dont-use-padding --import-picture-from wololo.jpg foo.flac'

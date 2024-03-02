#! /usr/bin/env bash

set -ex

# shellcheck source=../../lib/setcover_functions.sh
. lib/setcover_functions.sh


function metaflac {
    if [ $# -eq 4 ] && [ "$*" = '--list --block-type PICTURE foo.flac' ]
    then
        printf '%s\n' "$_list"
        return 0
    else
        : Not meant to be called that way.
        return 1
    fi
}


if ( get_flac_cover_front_block_nums; true )
then
    : Should have failed
    exit 1
fi
if ( get_flac_cover_front_block_nums ''; true )
then
    : Should have failed
    exit 1
fi


: No pic.

unset -v _list
status=0
out=$(get_flac_cover_front_block_nums foo.flac) || status=$?

test "$status" -eq 0
test -z "$out"


: One pic.

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
_DATA_
)

status=0
out=$(get_flac_cover_front_block_nums foo.flac) || status=$?

test "$status" -eq 0
test "$out" = 3


: Two pics.

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

status=0
out=$(get_flac_cover_front_block_nums foo.flac) || status=$?

test "$status" -eq 0
test "$out" = 3,6


: Three pics.

_list=$(
    cat << '_DATA_'
METADATA block #4
  type: 6 (PICTURE)
  is last: false
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
METADATA block #5
  type: 6 (PICTURE)
  is last: false
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

status=0
out=$(get_flac_cover_front_block_nums foo.flac) || status=$?

test "$status" -eq 0
test "$out" = 4,5,6


: Four pics.

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
METADATA block #4
  type: 6 (PICTURE)
  is last: false
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
METADATA block #5
  type: 6 (PICTURE)
  is last: false
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

status=0
out=$(get_flac_cover_front_block_nums foo.flac) || status=$?

test "$status" -eq 0
test "$out" = 3,4,5,6

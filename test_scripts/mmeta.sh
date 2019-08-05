#! /usr/bin/env bash

set -evx

readonly THE_SCRIPT=bin/mmeta


(
    # Mocks.
    function eyeD3 {
        printf '%s\n' "$_data_mp3"
    }
    function metaflac {
        printf '%s\n' "$_data_flac"
    }
    export -f eyeD3 metaflac
    unset -v _data_mp3 _data_flac
    export _data_mp3 _data_flac
    
    _data_mp3=$(
        cat << '_MOCK_DATA_'

1_-_echoes.mp3	[ 13.50 MB ]
-------------------------------------------------------------------------------
Time: 59:09	MPEG1, Layer III	[ 32 kb/s @ 44100 Hz - Joint stereo ]
-------------------------------------------------------------------------------
ID3 v2.3:
title: Echoes		artist: Cult of Luna
album: Salvation		year: 2004
boo
track: 1/8		genre: Post-Metal (id None)
Unique File ID: [http://musicbrainz.org] 47eca8de-483e-41e6-ac60-719b91460f2c

UserTextFrame: [Description: MusicBrainz Album Id]
0cdfcab5-4ea8-3f67-a588-6456f9d76ce3
UserTextFrame: [Description: musicbrainz_albumid]
0cdfcab5-4ea8-3f67-a588-6456f9d76ce3
UserTextFrame: [Description: MusicBrainz Album Artist Id]
d347406f-839d-4423-9a28-188939282afa
UserTextFrame: [Description: musicbrainz_albumartistid]
d347406f-839d-4423-9a28-188939282afa
UserTextFrame: [Description: MusicBrainz Artist Id]
d347406f-839d-4423-9a28-188939282afa
UserTextFrame: [Description: musicbrainz_artistid]
d347406f-839d-4423-9a28-188939282afa
UserTextFrame: [Description: CDDB DiscID]
74114a08
UserTextFrame: [Description: discid]
74114a08
UserTextFrame: [Description: MusicBrainz DiscID]
SzjcqF4HB_c8B3qQ_VT_rslm.Ys-
UserTextFrame: [Description: musicbrainz_discid]
SzjcqF4HB_c8B3qQ_VT_rslm.Ys-
UserTextFrame: [Description: Tagging time]
2015-12-07T17:37:29

FRONT_COVER Image: [Size: 26719 bytes] [Type: image/jpeg]
Description:

_MOCK_DATA_
    )
    
    fake_mp3_file=$(mktemp "${TMPDIR:-/tmp}"/mmeta-test-XXXXXXXX.mp3)
    
    _data_flac=$(
        cat << '_MOCK_DATA_'
METADATA block #0
  type: 0 (STREAMINFO)
  is last: false
  length: 34
  minimum blocksize: 4096 samples
  maximum blocksize: 4096 samples
  minimum framesize: 1447 bytes
  maximum framesize: 13887 bytes
  sample_rate: 44100 Hz
  channels: 2
  bits-per-sample: 16
  total samples: 23651712
  MD5 signature: a56db3e65dc3b8ebefc0c1988d1bd1bb
METADATA block #1
  type: 3 (SEEKTABLE)
  is last: false
  length: 972
  seek points: 54
    point 0: sample_number=0, stream_offset=0, frame_samples=4096
    point 1: sample_number=438272, stream_offset=1297134, frame_samples=4096
[…]
    point 53: sample_number=23371776, stream_offset=68402808, frame_samples=4096
METADATA block #2
  type: 4 (VORBIS_COMMENT)
  is last: false
  length: 183
  vendor string: reference libFLAC 1.3.0 20130526
  comments: 7
    comment[0]: ARTIST=Cult of Luna
    comment[1]: ALBUM=Eternal Kingdom
    comment[2]: TITLE=Following Betulas
    comment[3]: DATE=2008
    comment[4]: TRACKNUMBER=10
    comment[5]: CDDB=920e4a0a
    comment[6]: GENRE=Post-metal
METADATA block #3
  type: 6 (PICTURE)
  is last: false
  length: 31411
  type: 3 (Cover (front))
  MIME type: image/jpeg
  description: 
  width: 500
  height: 500
  depth: 24
  colors: 0 (unindexed)
  data length: 31369
  data:
    00000000: FF D8 FF E0 00 10 4A 46 49 46 00 01 01 01 00 48 ......JFIF.....H
[…]
    00007A80: 04 21 08 04 21 08 1F FF D9 00 00 00 00 00 00 00 .!..!....       
METADATA block #4
  type: 1 (PADDING)
  is last: true
  length: 8054
_MOCK_DATA_
    )
    
    fake_flac_file=$(mktemp "${TMPDIR:-/tmp}"/mmeta-test-XXXXXXXX.flac)
    
    test "$(
        "$THE_SCRIPT" '\n%f\n%a, “%t” [%l, %s]\n\t(“%A”, %y, %g)\n\n' "$fake_mp3_file"
    )" = "$(
        cat << _EXPECTED_

${fake_mp3_file}
Cult of Luna, “Echoes” [59:09, 13.50 MB]
	(“Salvation”, 2004, Post-Metal)

_EXPECTED_
    )"
    
    test "$(
        "$THE_SCRIPT" '\n%f\n%a, “%t” [%l, %s]\n\t(“%A”, %y, %g)\n\n' "$fake_flac_file"
    )" = "$(
        cat << _EXPECTED_

${fake_flac_file}
Cult of Luna, “Following Betulas” [Unknown, Unknown]
	(“Eternal Kingdom”, 2008, Post-metal)

_EXPECTED_
    )"
)

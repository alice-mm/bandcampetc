#! /usr/bin/env bash

set -ex

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


# Mock.
function unzip {
    if [ "$1" = '-l' ]
    then
        printf '%s\n' "$_data"
    fi
}


: Yes

for _data in 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpte.mp3
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpte.MP3
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpte.flac
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpte.FLAC
eétledpételdé
eélpedtpéelp plédtelép'
do
    mp3_or_flac_in_zip foo
done


: Nope

for _data in 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelptemp3
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpteMP3
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpteflac
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpteFLAC
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpte.txt
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
.mp3
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
.flac
eétledpételdé
eélpedtpéelp plédtelép'
do
    if mp3_or_flac_in_zip foo
    then
        : Should have failed
        exit 1
    fi
done

# No argument.
_data=foo.mp3
if (mp3_or_flac_in_zip; true)
then
    : Should have failed
    exit 1
fi

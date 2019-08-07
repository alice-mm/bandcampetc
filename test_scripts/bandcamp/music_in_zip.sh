#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


# Mock.
function unzip {
    if [ "$1" = '-l' ]
    then
        printf '%s\n' "$_data"
    fi
}

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
    ! mp3_or_flac_in_zip foo
done

# No argument.
_data=foo.mp3
! mp3_or_flac_in_zip

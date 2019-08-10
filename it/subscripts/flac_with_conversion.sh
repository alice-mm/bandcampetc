#! /usr/bin/env bash

set -evx

sed -i '
    s,^[ \t]*readonly CONVERT_TO_MP3=.*,readonly CONVERT_TO_MP3=1,
' config/bandcamp.sh
cp -v it/assets/fake_album_flac_version.zip ~/Downloads/
./bin/bandcamp

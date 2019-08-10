#! /usr/bin/env bash

function clean_between_runs {
    rm -vfr ~/{Downloads,Music}/*
}


set -evx

# Go to project.
cd /bc/


# Turn debug logs ON.
sed -i '
    s,^[ \t]*readonly PRINT_DEBUG=.*,readonly PRINT_DEBUG=1,
' config/bandcamp.sh

# Run UTs for good measure.
./run_tests.sh

# Make sure there is a Downloads directory.
# Idem for Music directory.
mkdir -pv ~/{Downloads,Music}/

# Set a no-op as text editor.
sed -i '
    s,^[ \t]*readonly EDITOR=(.*)[ \t]*$,readonly EDITOR=(:),
' config/bandcamp.sh


echo '1/3: FLAC without conversion.'
cp -v it/assets/fake_album_flac_version.zip ~/Downloads/
./bin/bandcamp

clean_between_runs

echo '2/3: FLAC with conversion.'
sed -i '
    s,^[ \t]*readonly CONVERT_TO_MP3=.*,readonly CONVERT_TO_MP3=1,
' config/bandcamp.sh
cp -v it/assets/fake_album_flac_version.zip ~/Downloads/
./bin/bandcamp

clean_between_runs

echo '3/3: MP3.'
cp -v it/assets/fake_album_mp3_version.zip ~/Downloads/
./bin/bandcamp

printf '%s: End.\n' "$(basename "$0")"

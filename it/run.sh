#! /usr/bin/env bash

function clean_between_runs {
    rm -vfr ~/{Downloads,Music}/*
}


set -ex

# Go to project.
cd /bc/

# Run UTs for good measure.
./run_tests.sh

# Make sure there is a Downloads directory.
# Idem for Music directory.
mkdir -pv ~/{Downloads,Music}/

# Set a no-op as text editor.
sed -i '
    s,^[ \t]*readonly EDITOR=(.*)[ \t]*$,readonly EDITOR=(:),
' config/bandcamp.sh


# List of subscripts to be run.
unset -v subs
subs=(
    flac_without_conversion.sh
    flac_with_conversion.sh
    mp3.sh
)

for k in "${!subs[@]}"
do
    if [ "$k" -gt 0 ]
    then
        clean_between_runs
    fi
    
    ./it/subscripts/"${subs[k]:?}"
done


printf '%s: End.\n' "$(basename "$0")"

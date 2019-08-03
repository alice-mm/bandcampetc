#! /usr/bin/env bash

# Get the name of the directory the current script sits in.
readonly SCR_DIR=$(
    dirname "$(readlink -f -- "$0")"
)

cd "$SRC_DIR" || exit

if (
    set -evx

    for file in test_scripts/*.sh
    do
        . "$file"
    done
)
then
    printf '%s: All done.\n' "$(basename "$0")"
    
    exit 0
else
    printf '%s: A test failed.\n' "$(basename "$0")" >&2
    
    exit 1
fi

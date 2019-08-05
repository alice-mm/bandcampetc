#! /usr/bin/env bash

# Get the name of the directory the current script sits in.
readonly SCR_DIR=$(
    dirname "$(readlink -f -- "$0")"
)

cd "$SRC_DIR" || exit

unset -v to_run

if [ $# -eq 0 ]
then
    # If no particular file was targeted, get them all.
    to_run=(./test_scripts/*.sh)
else
    to_run=("$@")
fi

for file in "${to_run[@]}"
do
    if ! "$file"
    then
        printf '%s: A test failed in: %q\n' \
                "$(basename "$0")" "$file" >&2
        exit 1
    fi
done

printf '%s: All done.\n' "$(basename "$0")"

exit 0

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


readonly TGRE=$(tput -T"${TERM:-xterm}" setaf 2 2> /dev/null)
readonly TRED=$(tput -T"${TERM:-xterm}" setaf 1 2> /dev/null)
readonly TNORM=$(tput -T"${TERM:-xterm}" sgr0 2> /dev/null)


for file in "${to_run[@]}"
do
    if ! "$file"
    then
        {
            echo
            echo
            printf " ${TRED}❌${TNORM} A test failed in: %q\n" "$file"
            echo
        } >&2
        exit 1
    fi
done

echo
echo
printf " ${TGRE}✓${TNORM} %q\n" "${to_run[@]}"
echo

printf '%s: All done.\n' "$(basename "$0")"

exit 0

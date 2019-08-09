#! /usr/bin/env bash

# Get the name of the directory the current script sits in.
readonly SCR_DIR=$(
    dirname "$(readlink -f -- "$0")"
)

cd "${SCR_DIR:?}" || exit

unset -v to_run

if [ $# -eq 0 ]
then
    # If no particular file was targeted, get them all.
    to_run=(./test_scripts/{,*/}*.sh)
else
    to_run=("$@")
fi


readonly TGRE=$(tput -T"${TERM:-xterm}" setaf 2 2> /dev/null)
readonly TRED=$(tput -T"${TERM:-xterm}" setaf 1 2> /dev/null)
readonly TNORM=$(tput -T"${TERM:-xterm}" sgr0 2> /dev/null)


unset -v ok_files
ok_files=()

for file in "${to_run[@]}"
do
    if [ ! -f "$file" ]
    then
        printf '%s: Skipping file “%s” (not found).\n' \
                "$(basename "$0")" "$file" >&2
        continue
    fi
    
    if "$file"
    then
        ok_files+=("$file")
    else
        {
            echo
            echo
            printf " ${TRED}❌${TNORM} A test failed in: %q\n" "$file"
            echo
        } >&2
        exit 1
    fi
done

if [ ${#ok_files[@]} -gt 0 ]
then
    echo
    echo
    printf " ${TGRE}✓${TNORM} %q\n" "${ok_files[@]}"
    echo
fi

printf '%s: All done (%d files).\n' "$(basename "$0")" "${#ok_files[@]}"

exit 0

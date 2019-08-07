#! /usr/bin/env bash

set -evx

. lib/bandcamp_functions.sh


# Mock “mv” to check executions.
function mv {
    _called=1
    
    if [ $# -eq 4 ] &&
        [ "$1" = "${_expected[0]}" ] &&
        [ "$2" = "${_expected[1]}" ] &&
        [ "$3" = "${_expected[2]}" ] &&
        [ "$4" = "${_expected[3]}" ]
    then
        _ok=1
    fi
    
    return 0
}

unset -v _expected

unset -v _ok
_expected=(-n -- foo/bar/plop.txt foo/bar/poire.tgz)
my_renamer foo/bar/plop.txt poire.tgz
test "$_ok"

unset -v _ok
_expected=(-n -- plop.txt ./poire.tgz)
my_renamer plop.txt poire.tgz
test "$_ok"

# Strange case, but supported.
unset -v _ok
_expected=(-n -- ./plop.txt ./gna/poire.tgz)
my_renamer ./plop.txt gna/poire.tgz
test "$_ok"

# No mv call if the file’s name does not need to change.
unset -v _called
my_renamer ././. .
test ! "$_called"

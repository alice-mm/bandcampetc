#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


function clean_hierarchy {
    _called=1
}

unset -v _called CLEAN_HIERARCHY
clean_hierarchy_if_needed
test ! "$_called"

unset -v _called
CLEAN_HIERARCHY=1
clean_hierarchy_if_needed
test "$_called"

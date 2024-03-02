#! /usr/bin/env bash

set -ex

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


# Get the name of the directory the current script sits in.
readonly SCR_DIR=$(dirname "$(readlink -f -- "$0")")
RENAME=${SCR_DIR}/../../bin/to_acceptable_name
test -x "$RENAME"

# No music directory set.
if ( compute_final_dir_path; true )
then
    : Should have failed
    exit 1
fi

DIR_M=poire/tourte

unset -v meta
test "$(compute_final_dir_path meta)" = poire/tourte/_/_

unset -v meta
declare -A meta=(
    [albumartist]='A b C de'
)
test "$(compute_final_dir_path meta)" = poire/tourte/a_b_c_de/_

unset -v meta
declare -A meta=(
    [album]='fg % @ (LSILSI) foo'
)
test "$(compute_final_dir_path meta)" = poire/tourte/_/fg_at_lsilsi_foo

unset -v meta
declare -A meta=(
    [albumartist]='A b C de'
    [album]='fg % @ (LSILSI) foo'
)
test "$(compute_final_dir_path meta)" = poire/tourte/a_b_c_de/fg_at_lsilsi_foo

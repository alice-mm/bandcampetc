#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


! ( get_artist_for_track; true )
! ( get_artist_for_track foo; true )
! ( get_artist_for_track 1; true )


unset -v meta
declare -A meta
: No data.
test -z "$(get_artist_for_track 3 meta)"

unset -v meta
declare -A meta=( [artist]='Foo Bar' )
: Just global artist.
test "$(get_artist_for_track 3 meta)" = 'Foo Bar'

unset -v meta
declare -A meta=( [a3]='Cus Tom' )
: Just custom artist.
test "$(get_artist_for_track 3 meta)" = 'Cus Tom'

unset -v meta
declare -A meta=(
    [artist]='Foo Bar'
    [a3]='Cus Tom'
)
: Both.
test "$(get_artist_for_track 3 meta)" = 'Cus Tom'

unset -v meta
declare -A meta=(
    [artist]='Foo Bar'
    [a3]='Cus Tom'
)
: Both but wrong track.
test "$(get_artist_for_track 4 meta)" = 'Foo Bar'

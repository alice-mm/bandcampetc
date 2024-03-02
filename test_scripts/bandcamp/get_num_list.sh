#! /usr/bin/env bash

set -ex

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


test "$(get_override_track_nums 'a1')" = '1'

test "$(get_override_track_nums 'a1,2')" = '1
2'

test "$(get_override_track_nums 'a1,7')" = '1
7'

test "$(get_override_track_nums 'A   2')" = '2'

test "$(get_override_track_nums 'a4-7')" = '4
5
6
7'

test "$(get_override_track_nums 'a4  -   7')" = '4
5
6
7'

: Mix.
test "$(get_override_track_nums 'A3, 7-9, 13')" = '3
7
8
9
13'

: Mix in strange order.
test "$(get_override_track_nums 'A7-9, 3, 13')" = '3
7
8
9
13'

: Ignored garbage.
test "$(get_override_track_nums 'A lsi lsp3, Æ7-9, # 1_3')" = '3
7
8
9
13'

: Multiple lines. Should ignore after the first.
test "$(get_override_track_nums $'a3,5-7\na8\n\na9-99')" = '3
5
6
7'

: Implicit start bound.
test "$(get_override_track_nums 'a-4')" = '1
2
3
4'

: Extraneous zeroes.
test "$(get_override_track_nums 'A 00000004 ,  000090')" = '4
90'

: Absurd number. Should print nothing on stdout but something on stderr.
test -z "$(get_override_track_nums 'a98765')"
[[ "$(get_override_track_nums 'a98765' 2>&1 > /dev/null)" =~ 'Could not process track list' ]]

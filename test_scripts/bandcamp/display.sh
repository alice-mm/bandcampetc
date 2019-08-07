#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


TBOLD='<bold>'
TNORM='<norm>'

test "$(display_record_info '' meta)" = "$(

    cat << _EXPECTED_

  ╭────────────────────────────────────────────╌╌┄┄┈┈
  │ ${TBOLD}Type:  ${TNORM}  ??
  │ ${TBOLD}Artist:${TNORM}  ??
  │ ${TBOLD}Album: ${TNORM}  “??”
  ╰────────────────────────────────────────────╌╌┄┄┈┈

_EXPECTED_
)"

test "$(display_record_info tYpE meta)" = "$(

    cat << _EXPECTED_

  ╭────────────────────────────────────────────╌╌┄┄┈┈
  │ ${TBOLD}Type:  ${TNORM}  TYPE
  │ ${TBOLD}Artist:${TNORM}  ??
  │ ${TBOLD}Album: ${TNORM}  “??”
  ╰────────────────────────────────────────────╌╌┄┄┈┈

_EXPECTED_
)"

unset -v meta
declare -A meta
meta=(
    [artist]='some ARTIST'
    [album]='SOME album'
)

test "$(display_record_info tYpE meta)" = "$(

    cat << _EXPECTED_

  ╭────────────────────────────────────────────╌╌┄┄┈┈
  │ ${TBOLD}Type:  ${TNORM}  TYPE
  │ ${TBOLD}Artist:${TNORM}  some ARTIST
  │ ${TBOLD}Album: ${TNORM}  “SOME album”
  ╰────────────────────────────────────────────╌╌┄┄┈┈

_EXPECTED_
)"


test "$(display_progress)" \
        = "<bold>$(basename "$0"):<norm> Track ?? of ??..."

test "$(display_progress foo bar)" \
        = "<bold>$(basename "$0"):<norm> Track ?? of ??..."

test "$(display_progress 0 -1)" \
        = "<bold>$(basename "$0"):<norm> Track ?? of ??..."

test "$(display_progress 1 lsilsilsi)" \
        = "<bold>$(basename "$0"):<norm> Track 1 of ??..."

test "$(display_progress 03 0047)" \
        = "<bold>$(basename "$0"):<norm> Track 3 of 47..."

test "$(display_progress 03 '')" \
        = "<bold>$(basename "$0"):<norm> Track 3 of ??..."

test "$(display_progress 3 7)" \
        = "<bold>$(basename "$0"):<norm> Track 3 of 7..."

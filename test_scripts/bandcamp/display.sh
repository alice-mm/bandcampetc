#! /usr/bin/env bash

set -evx

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

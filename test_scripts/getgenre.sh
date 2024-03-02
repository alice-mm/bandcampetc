#! /usr/bin/env bash

set -ex

readonly THE_SCRIPT=bin/getgenre

curl() {
    if [[ $* = *${_EXPECTED_MOCKED_CURL_ARGS_PATTERN}* ]]
    then
        printf '%s\n' "$_MOCKED_CURL_TEST_DATA"
    else
        : Wrong arguments
        exit 1
    fi
}
export -f curl

artist_data=$(
    cat << '_JSON_'
{
  "artists": [
    {
      "tags": [
        {
          "count": 2,
          "name": "jazz"
        },
        {
          "count": 3,
          "name": "jazz fusion"
        },
        {
          "count": -1,
          "name": "oklahoma"
        },
        {
          "count": 1,
          "name": "free jazz"
        }
      ]
    }
  ]
}
_JSON_
)

release_data=$(
    cat << '_JSON_'
{
  "release-groups": [
    {
      "tags": [
        {
          "count": 2,
          "name": "jazz"
        },
        {
          "count": 3,
          "name": "jazz fusion"
        },
        {
          "count": -1,
          "name": "oklahoma"
        },
        {
          "count": 1,
          "name": "free jazz"
        }
      ]
    }
  ]
}
_JSON_
)

export _EXPECTED_MOCKED_CURL_ARGS_PATTERN='/ws/2/artist/*plop'

export _MOCKED_CURL_TEST_DATA
_MOCKED_CURL_TEST_DATA=$artist_data


: Missing parameters

if stderr=$("$THE_SCRIPT" -r foo 2>&1 > /dev/null)
then
    : Should have failed
    exit 1
fi

[[ ${stderr,,} = *'no artist name'* ]]


: Artist search

test "$("$THE_SCRIPT" -a plop)" = 'Jazz fusion'
test "$("$THE_SCRIPT" -a plop -n 3)" = "$(
    cat << '_EXPECTED_'
Jazz fusion
Jazz
Free jazz
_EXPECTED_
)"


: Release search

_MOCKED_CURL_TEST_DATA=$release_data
export _EXPECTED_MOCKED_CURL_ARGS_PATTERN='/ws/2/release-group/*artistname%3Aplop*releasegroup%3Ayo'

test "$("$THE_SCRIPT" -a plop -r yo)" = 'Jazz fusion'
test "$("$THE_SCRIPT" -a plop -r yo -n 3)" = "$(
    cat << '_EXPECTED_'
Jazz fusion
Jazz
Free jazz
_EXPECTED_
)"


: Fail for release, fall back on artist

# Using the artist-focused data will, as a side effect,
# force release search to fail, as the release-focused JSON paths
# will yield nothing there.
_MOCKED_CURL_TEST_DATA=$artist_data
# Lenient pattern since we’ll be handling two requests this time.
export _EXPECTED_MOCKED_CURL_ARGS_PATTERN='/ws/2/*plop'

test "$("$THE_SCRIPT" -a plop -r yo)" = 'Jazz fusion'
test "$("$THE_SCRIPT" -a plop -r yo -n 3)" = "$(
    cat << '_EXPECTED_'
Jazz fusion
Jazz
Free jazz
_EXPECTED_
)"

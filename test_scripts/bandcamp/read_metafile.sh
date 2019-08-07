#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


: Normal, but dirty file.

METAFILE=$(mktemp "${TMPDIR:-/tmp}"/bandcamp-test-XXXXXXXX)

cat > "$METAFILE" << '_DATA_'

SKIP        = n

# Comment blah blah.

#Comment too.

ARTIST      = foo
ALBUMARTIST      =bar


 456=             t c

ALBUM          = yo
# idlbul ébisbél sid DIpesaéjepaEJLSP

YEAR        = 1234
GENRE         =cool

1 = t a

  23     =t b

_DATA_

unset -v m
declare -A m
read_metafile m nya

test "${m[artist]}"         = foo
test "${m[albumartist]}"    = bar
test "${m[album]}"          = yo
test "${m[year]}"           = 1234
test "${m[genre]}"          = cool

test ${#nya[@]} -eq 3
test "${nya[1]}"    = 't a'
test "${nya[23]}"   = 't b'
test "${nya[456]}"  = 't c'

test "${m[maxtrack]}" = 456



: Skipped album.

cat > "$METAFILE" << '_DATA_'

SKIP        = y

# Comment blah blah.

#Comment too.

ARTIST      = foo
ALBUMARTIST      =bar


 456=             t c

ALBUM          = yo
# idlbul ébisbél sid DIpesaéjepaEJLSP

YEAR        = 1234
GENRE         =cool

1 = t a

  23     =t b

_DATA_

# Should skip this album.
unset -v m
declare -A m
! read_metafile m tracks



: No data.

cat > "$METAFILE" << '_DATA_'

SKIP        = n

# No data!
_DATA_

unset -v m
declare -A m
read_metafile m plop

# Should be all default values.

test -z "${m[artist]}"
test -z "${m[albumartist]}"
test -z "${m[album]}"
test -z "${m[year]}"
test -z "${m[genre]}"

test ${#plop[@]} -eq 0
test -z "${plop[1]}"
test -z "${plop[23]}"
test -z "${plop[456]}"

test "${m[maxtrack]}" = 0

cat > "$METAFILE" << '_DATA_'

SKIP        = n
ALBUM = plop = plup=plap

_DATA_

unset -v m
declare -A m
read_metafile m tracks

# Should Read correctly even if “=” in value.
test "${m[album]}" = 'plop = plup=plap'

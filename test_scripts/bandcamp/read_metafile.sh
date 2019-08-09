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


: '=' in value.

unset -v m
declare -A m
read_metafile m tracks

# Should Read correctly even if “=” in value.
test "${m[album]}" = 'plop = plup=plap'


: Override artist

echo '   a7    =  Foo Bar' > "$METAFILE"
unset -v m
declare -A m
read_metafile m tracks
test "${m[a7]}" = 'Foo Bar'


: Override artist, capital

echo '   A7    =  Foo Bar' > "$METAFILE"
unset -v m
declare -A m
read_metafile m tracks
test "${m[a7]}" = 'Foo Bar'


: Override artist, spaces

echo '   a    7    =  Foo Bar' > "$METAFILE"
unset -v m
declare -A m
read_metafile m tracks
test "${m[a7]}" = 'Foo Bar'


: Override artist, list

echo '   a3,7,167    =  Foo Bar' > "$METAFILE"
unset -v m
declare -A m
read_metafile m tracks
test "${m[a3]}" = 'Foo Bar'
test "${m[a7]}" = 'Foo Bar'
test "${m[a167]}" = 'Foo Bar'
test -z "${m[a1]}"
test -z "${m[a2]}"
test -z "${m[a4]}"
test -z "${m[a50]}"


: Override artist, list with weird spacing

echo '   a3  , 7,    167=  Foo Bar' > "$METAFILE"
unset -v m
declare -A m
read_metafile m tracks
test "${m[a3]}" = 'Foo Bar'
test "${m[a7]}" = 'Foo Bar'
test "${m[a167]}" = 'Foo Bar'
test -z "${m[a1]}"
test -z "${m[a2]}"
test -z "${m[a4]}"
test -z "${m[a50]}"


: Override artist, interval

echo 'a3-7 = Foo Bar' > "$METAFILE"
unset -v m
declare -A m
read_metafile m tracks
test "${m[a3]}" = 'Foo Bar'
test "${m[a4]}" = 'Foo Bar'
test "${m[a5]}" = 'Foo Bar'
test "${m[a6]}" = 'Foo Bar'
test "${m[a7]}" = 'Foo Bar'
test -z "${m[a1]}"
test -z "${m[a2]}"
test -z "${m[a8]}"


: Override artist, interval with weird spacing and capital

echo 'A 3  -   7 =Foo Bar' > "$METAFILE"
unset -v m
declare -A m
read_metafile m tracks
test "${m[a3]}" = 'Foo Bar'
test "${m[a4]}" = 'Foo Bar'
test "${m[a5]}" = 'Foo Bar'
test "${m[a6]}" = 'Foo Bar'
test "${m[a7]}" = 'Foo Bar'
test -z "${m[a1]}"
test -z "${m[a2]}"
test -z "${m[a8]}"


: Override artist, mix

echo 'a2,5-7,137 = Foo Bar' > "$METAFILE"
unset -v m
declare -A m
read_metafile m tracks
test "${m[a2]}" = 'Foo Bar'
test "${m[a5]}" = 'Foo Bar'
test "${m[a6]}" = 'Foo Bar'
test "${m[a7]}" = 'Foo Bar'
test "${m[a137]}" = 'Foo Bar'
test -z "${m[a1]}"
test -z "${m[a3]}"
test -z "${m[a4]}"
test -z "${m[a8]}"
test -z "${m[a136]}"
test -z "${m[a138]}"


: Override artist, mix with weird spacing and capital

echo '  A  2 ,5-  7,    137=  Foo Bar' > "$METAFILE"
unset -v m
declare -A m
read_metafile m tracks
test "${m[a2]}" = 'Foo Bar'
test "${m[a5]}" = 'Foo Bar'
test "${m[a6]}" = 'Foo Bar'
test "${m[a7]}" = 'Foo Bar'
test "${m[a137]}" = 'Foo Bar'
test -z "${m[a1]}"
test -z "${m[a3]}"
test -z "${m[a4]}"
test -z "${m[a8]}"
test -z "${m[a136]}"
test -z "${m[a138]}"


: Override artist with ignored garbage characters

echo '  A  ce2 u #,5- dtdteÆ 7  ĳ,    13_7=  Foo Bar' > "$METAFILE"
unset -v m
declare -A m
read_metafile m tracks
test "${m[a2]}" = 'Foo Bar'
test "${m[a5]}" = 'Foo Bar'
test "${m[a6]}" = 'Foo Bar'
test "${m[a7]}" = 'Foo Bar'
test "${m[a137]}" = 'Foo Bar'
test -z "${m[a1]}"
test -z "${m[a3]}"
test -z "${m[a4]}"
test -z "${m[a8]}"
test -z "${m[a136]}"
test -z "${m[a138]}"


: Override artist twice with different names.

{
    echo 'a4 = Foo' 
    echo 'a7 = Bar'
} > "$METAFILE"
unset -v m
declare -A m
read_metafile m tracks
test "${m[a4]}" = Foo
test "${m[a7]}" = Bar
test -z "${m[a1]}"
test -z "${m[a2]}"
test -z "${m[a3]}"
test -z "${m[a5]}"
test -z "${m[a6]}"
test -z "${m[a8]}"

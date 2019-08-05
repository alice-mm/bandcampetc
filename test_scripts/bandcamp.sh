#! /usr/bin/env bash

set -evx

. lib/bandcamp_functions.sh


# my_renamer
(
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
)

# read_metafile
(
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
    
    read_metafile
    
    test "$metaartist"      = foo
    test "$metaalbumartist" = bar
    test "$metaalbum"       = yo
    test "$metayear"        = 1234
    test "$metagenre"       = cool
    
    test ${#metatracks[@]} -eq 3
    test "${metatracks[1]}"     = 't a'
    test "${metatracks[23]}"    = 't b'
    test "${metatracks[456]}"   = 't c'
    
    test "$metamaxtrack" = 456
    
    
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
    ! read_metafile
    
    cat > "$METAFILE" << '_DATA_'

SKIP        = n

# No data!
_DATA_
    
    read_metafile
    
    # Should be all default values.
    
    test -z "$metaartist"
    test -z "$metaalbumartist"
    test -z "$metaalbum"
    test -z "$metayear"
    test -z "$metagenre"
    
    test ${#metatracks[@]} -eq 0
    test -z "${metatracks[1]}"
    test -z "${metatracks[23]}"
    test -z "${metatracks[456]}"
    
    test "$metamaxtrack" = 0
    
    cat > "$METAFILE" << '_DATA_'

SKIP        = n
ALBUM = plop = plup=plap

_DATA_
    
    read_metafile
    
    # Should Read correctly even if “=” in value.
    test "$metaalbum" = 'plop = plup=plap'
)

#! /usr/bin/env bash

set -evx

. lib/bandcamp_functions.sh


# Music in ZIP?
(
    # Mock.
    function unzip {
        if [ "$1" = '-l' ]
        then
            printf '%s\n' "$_data"
        fi
    }
    
    for _data in 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpte.mp3
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpte.MP3
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpte.flac
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpte.FLAC
eétledpételdé
eélpedtpéelp plédtelép'
    do
        mp3_or_flac_in_zip foo
    done
    
    for _data in 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelptemp3
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpteMP3
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpteflac
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpteFLAC
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
leétpelpte.txt
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
.mp3
eétledpételdé
eélpedtpéelp plédtelép' 'seljpsjpbse
peljséjpseéjp épet ldpe
.flac
eétledpételdé
eélpedtpéelp plédtelép'
    do
        ! mp3_or_flac_in_zip foo
    done
    
    # No argument.
    _data=foo.mp3
    ! mp3_or_flac_in_zip
)

# Get record format
(
    tdir=$(mktemp -d "${TMPDIR:-/tmp}"/bandcamp-test-XXXXXXXX)
    
    cd "${tdir:?}"
    
    : Empty dir.
    sample=$(get_sample_file)
    test -z "$sample"
    test -z "$(get_record_format "$sample")"
    
    : Irrelevant files.
    touch foo.txt bar.gif PLOP.PNG POIRE.JPG .mp3 .flac .MP3 .FLAC
    sample=$(get_sample_file)
    test -z "$sample"
    test -z "$(get_record_format "$sample")"
    
    : MP3.
    touch nya.mp3
    sample=$(get_sample_file)
    test "$sample" = ./nya.mp3
    test "$(get_record_format "$sample")" = mp3
    rm nya.mp3
    touch NYA.MP3
    sample=$(get_sample_file)
    test "$sample" = ./NYA.MP3
    test "$(get_record_format "$sample")" = mp3
    rm NYA.MP3
    
    : FLAC.
    touch nya.flac
    sample=$(get_sample_file)
    test "$sample" = ./nya.flac
    test "$(get_record_format "$sample")" = flac
    rm nya.flac
    touch NYA.FLAC
    sample=$(get_sample_file)
    test "$sample" = ./NYA.FLAC
    test "$(get_record_format "$sample")" = flac
    rm NYA.FLAC
    
    : Both.
    touch nya.mp3 nya.flac
    sample=$(get_sample_file)
    test "$sample" = ./nya.mp3 || test "$sample" = ./nya.flac
    res=$(get_record_format "$sample")
    test "$res" = mp3 || test "$res" = flac
)

# Retag FLAC
(
    # Mock + check.
    function metaflac {
        # “--dont-use-padding” + 6 tags to rm and add back + file.
        test $# -eq $((2 + 6 * 2))
        
        test "$1" = --dont-use-padding
        
        test "$2" = --remove-tag=TITLE
        test "$3" = --remove-tag=ARTIST
        test "$4" = --remove-tag=ALBUMARTIST
        test "$5" = --remove-tag=ALBUM
        test "$6" = --remove-tag=GENRE
        test "$7" = --remove-tag=DATE
        
        test "$8"       = --set-tag=TITLE='foo bar'
        test "$9"       = --set-tag=ARTIST='a r t i s t'
        test "${10}"    = --set-tag=ALBUMARTIST='alb ar'
        test "${11}"    = --set-tag=ALBUM='bu bu BUM'
        test "${12}"    = --set-tag=GENRE='Esoteric genre'
        test "${13}"    = --set-tag=DATE=1324
        
        test "${14}" = foo.flac
    }
    
    unset -v tags
    declare -A tags
    tags[title]='foo bar';
    tags[artist]='a r t i s t'
    tags[albumartist]='alb ar'
    tags[album]='bu bu BUM'
    tags[genre]='Esoteric genre'
    tags[year]=1324
    retag_flac foo.flac tags
)

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

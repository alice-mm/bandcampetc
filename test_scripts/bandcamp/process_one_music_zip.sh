#! /usr/bin/env bash

set -ex

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


if ( process_one_music_zip; true )
then
    : Should have failed
    exit 1
fi

COVERS=mock_covers

# Calls will be written here.
callfile=$(mktemp "${TMPDIR:-/tmp}"/bandcamp-init-test-XXXXXXXX)
test "$callfile"
test -r "$callfile"

# $1    Name of function or program called.
# $2…n  Args of it.
function _mock {
    local old_ifs=$IFS
    
    IFS=','
    printf '%s\n' "${1:-??}(${*:2})" >> "$callfile"
    
    IFS=$old_ifs
}

function unzip {
    _mock unzip "$@"
}
function init_metadata {
    _mock init_metadata "$@"
}
function display_record_info {
    _mock display_record_info "$@"
}
function print_metafile_content {
    _mock print_metafile_content "$@"
}
function edit_metafile {
    _mock edit_metafile "$@"
}
function read_metafile {
    _mock read_metafile "$@"
}
function process_one_source_file {
    _mock process_one_source_file "$@"
}
function process_and_move_existing_cover {
    _mock process_and_move_existing_cover "$@"
}
function mock_covers {
    _mock mock_covers "$@"
}
function apply_cover_if_we_got_one {
    _mock apply_cover_if_we_got_one "$@"
}
function get_and_store_other_files {
    _mock get_and_store_other_files "$@"
}
function clean_all_file_names {
    _mock clean_all_file_names "$@"
}
function clean_hierarchy_if_needed {
    _mock clean_hierarchy_if_needed "$@"
}
function rm {
    _mock rm "$@"
}

function look_for_existing_cover { :; }

# Real subscript.
readonly SCR_DIR=$(dirname "$(readlink -f -- "$0")")
RENAME=${SCR_DIR}/../../bin/to_acceptable_name
test -x "$RENAME"

# Discard metafile instead of creating useless junk.
METAFILE=/dev/null

# Temp test dir to fiddle around.
tdir=$(mktemp -d "${TMPDIR:-/tmp}"/bandcamp-process-zip-XXXXXXXX)
cd "${tdir:?}"

# “bandcamp” config.
DIR_M=${tdir}/poire/tourte

# Dummy sample file to make sure it gets stored in the right place.
mkdir -p foo/
touch foo/bar.mp3

process_one_music_zip /some/path/to/foo.zip

diff "$callfile" <(
    cat << _EXPECTATIONS_
unzip(foo.zip)
init_metadata(./foo/bar.mp3,_meta)
display_record_info(mp3,_meta)
print_metafile_content(mp3,_meta)
edit_metafile()
read_metafile(_meta,_tracks)
process_one_source_file(storage/mp3/bar.mp3,_meta,_tracks)
mock_covers(storage/)
apply_cover_if_we_got_one(mp3)
get_and_store_other_files()
clean_all_file_names(_meta)
clean_hierarchy_if_needed(${tdir}/poire/tourte/_/_)
rm(-v,--,/some/path/to/foo.zip)
_EXPECTATIONS_
)

test -r poire/tourte/_/_/mp3/bar.mp3


: Test with a found cover.

# Empty “call file”.
> "$callfile"

# Empty temp dir.
# We need to temporarily discard the mock…
unset -f rm
rm -r -- "${tdir:?}"/*
function rm { _mock rm "$@"; }

# Dummy sample file to make sure it gets stored in the right place.
mkdir -p foo/
touch foo/bar.mp3

function look_for_existing_cover { echo nsunsu.jpg; }

process_one_music_zip /some/path/to/foo.zip

diff "$callfile" <(
    cat << _EXPECTATIONS_
unzip(foo.zip)
init_metadata(./foo/bar.mp3,_meta)
display_record_info(mp3,_meta)
print_metafile_content(mp3,_meta)
edit_metafile()
read_metafile(_meta,_tracks)
process_one_source_file(storage/mp3/bar.mp3,_meta,_tracks)
process_and_move_existing_cover(nsunsu.jpg)
apply_cover_if_we_got_one(mp3)
get_and_store_other_files()
clean_all_file_names(_meta)
clean_hierarchy_if_needed(${tdir}/poire/tourte/_/_)
rm(-v,--,/some/path/to/foo.zip)
_EXPECTATIONS_
)

test -r poire/tourte/_/_/mp3/bar.mp3

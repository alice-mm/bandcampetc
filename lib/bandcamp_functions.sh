#! /usr/bin/env bash


# For internal use via the logging functions below.
#
# $1    String added between the program name and the message,
#       typically to specify the log level.
# $2    Printf-style format string.
# $3…n  Arguments for printf.
function _f_log {
    local prog
    
    prog=${TBOLD}$(basename "$0"):${TNORM}
    
    printf "%s %s${2}\n" "$prog" "$1" "${@:3}"
}

# Only has an effect if PRINT_DEBUG is not empty.
# $1    Printf-style format string.
# $2…n  Arguments for printf.
function debug {
    if [ "$PRINT_DEBUG" ]
    then
        _f_log 'Debug: ' "$@"
    fi
}

# $1    Printf-style format string.
# $2…n  Arguments for printf.
function log {
    _f_log '' "$@"
}

# $1    Printf-style format string.
# $2…n  Arguments for printf.
function warn {
    _f_log "${TYEL}Warning:${TNORM} " "$@" >&2
}

# $1    Printf-style format string.
# $2…n  Arguments for printf.
function err {
    _f_log "${TRED}Error:${TNORM} " "$@" >&2
}


# $1    Path to target file.
# $2    New basename.
function my_renamer {
    local old=${1:?No target file given.}
    local new
    
    new=$(dirname "$1")/${2:?No new basename given.}
    
    if ! [ "$old" -ef "$new" ]
    then
        mv -n -- "$old" "$new" &&
        printf ' “%s” → “%s”\n' "$(basename "$old")" "$2"
    fi
}


# Wrapper for “clean_hierarchy” that does nothing (successfully) if
# the configuration does not ask for cleaning.
# $@    Argument for “clean_hierarchy”.
function clean_hierarchy_if_needed {
    if [ "$CLEAN_HIERARCHY" ]
    then
        clean_hierarchy "$@"
        return
    else
        debug 'Not trying to clean.'
        return 0
    fi
}


# $1    Path to a directory.
#
# If the given directory X contains nothing but another directory Y,
# take the contents of Y, place them directly under X, and remove Y.
#
# Exit status:
#   0   if the hierarchy was simplified.
#   1   if error.
#   10  if the hierarchy is too complicated to be simplified.
function clean_hierarchy {
    : "${1:?No path given.}"
    
    local -i nb
    local the_only_item
    
    if [ ! -d "$1" ]
    then
        err 'No “%s” directory.' "$1"
        return 1
    fi
    
    nb=$(find "$1" -mindepth 1 -maxdepth 1 -printf 1 | wc -c)
    
    # There should be one item.
    if [ "$nb" -ne 1 ]
    then
        return 10
    fi
    
    the_only_item=$(find "$1" -mindepth 1 -maxdepth 1 -type d)
    
    # The only item should be a directory.
    if [ -z "$the_only_item" ]
    then
        return 10
    fi
    
    # One of the files in the lower directory might bear the same name as the
    # directory itself. And hidden files are painful to handle
    # with a simple “mv + *”. I’ll just move the lower directory away
    # and sync it with its parent. /shrug
    local tdir=$(mktemp -d "${TMPDIR:-/tmp}"/bandcamp-cleaning-XXXXXXXX)
    
    if ! mv -- "$the_only_item" "$tdir"/
    then
        err 'Failed to clean hierarchy: mv %q %q' "$the_only_item" "$tdir"/
        return 1
    fi
    
    if rsync -au -- "$tdir"/"$(basename "$the_only_item")"/ "$1"/
    then
        if ! rm -fr -- "$tdir"/
        then
            warn 'Failed to remove temporary directory “%s”.' "$tdir"/
        fi
        
        debug 'Moved files directly under “%s” to clean the hierarchy.' "$1"/
        return 0
    else
        err 'Failed to clean hierarchy: rsync -au %q %q' \
                "$tdir"/"$(basename "$the_only_item")"/ "$1"/
        
        if mv -n -- "$tdir"/"$(basename "$the_only_item")" "$1"/
        then
            log 'Reverted partial cleaning.'
        else
            err 'Failed to revert partial cleaning.'
        fi
        
        return 1
    fi
}


# $1    Path to ZIP archive.
# Exits with 0 status iff it contains a “.mp3” or “.flac” file.
function mp3_or_flac_in_zip {
    unzip -l "${1:?No archive given.}" | grep -iqE '.\.(flac|mp3)$'
}


# Find out if there is MP3 or FLAC in or below the working directory.
# Get the first file of one of these types we can find.
# If both types are present, one will be kind of randomly ignored.
#
# stdout → Path to the file.
function get_sample_file {
    find . -iregex '.*[^/]\.\(flac\|mp3\)' -print -quit
}


# Print the lowercase extension of an MP3 or FLAC file.
#
# $1    The file.
function get_record_format {
    local sample_file=${1:?No file given.}
    local ext
    
    ext=${sample_file##*.}
    
    printf '%s\n' "${ext,,}"
}


# $1    Track number “n”.
# $2    Name of external metadata associative array “m”.
#
# stdout →  m[a<n>] if not empty, otherwise m[artist].
function get_artist_for_track {
    local -i n=$1
    
    : "${n:?No track number given.}"
    : "${2:?No array name given.}"
    
    if [ "$2" != t ]
    then
        local -n t=$2
    fi
    
    printf '%s\n' "${t[a${n}]:-${t['artist']}}"
}


# $1    FLAC file to retag.
# $2    Track number.
# $3    Human-friendly song title.
# $4    Name of an associative array with fields:
#           artist
#           albumartist
#           album
#           genre
#           year
function retag_flac {
    : "${1:?No file given.}"
    : "${2:?No track number given.}"
    : "${3:?No song title given.}"
    : "${4:?No array name given.}"
    
    if [ "$4" != t ]
    then
        local -n t=$4
    fi
    
    local -a optns
    local -i safe_year
    
    optns=(
        --dont-use-padding
        
        --remove-tag=TITLE
        --remove-tag=ARTIST
        --remove-tag=ALBUMARTIST
        --remove-tag=ALBUM
        --remove-tag=GENRE
        --remove-tag=DATE
        
        --set-tag="TITLE=${3}"
        --set-tag="ARTIST=$(get_artist_for_track "$2" t)"
        --set-tag="ALBUMARTIST=${t[albumartist]}"
        --set-tag="ALBUM=${t[album]}"
        --set-tag="GENRE=${t[genre]}"
    )
    
    safe_year=$(tr -cd '0-9' <<< "${t[year]}")
    
    if [ "$safe_year" ] && [ "$safe_year" -gt 0 ]
    then
        optns+=(
            --set-tag="DATE=${safe_year}"
        )
    fi
    
    metaflac "${optns[@]}" "$1"
}


# Display an error with $@ as info.
function error_while_tagging_mp3 {
    {
        err 'Tagging error. Options were:'
        echo
        printf '\t%q\n' "$@"
        echo
    } >&2
}


# Try to look for music of the same artist to find out what the genre is.
# If something suitable is found, it is printed to stdout.
#
# $1    Name of the artist.
function try_to_guess_genre {
    : "${1:?No artist given.}"
    
    # Get a few random files for this artist
    # and try to see what their genre is.
    # Exclude empty answers, sort, count “votes”.
    # The most frequent answer wins.
    find "$DIR_M"/"$("$RENAME" <<< "$1")"/ -type f \
            '(' -iname '*.mp3' -or -iname '*.flac' ')' 2> /dev/null \
            | shuf | head -5 \
            | xargs --no-run-if-empty "$MMETA" -e '%g\n' 2> /dev/null \
            | awk 'length > 1' | sort | uniq -c | sort -k1,1nr | head -1 \
            | sed $'s/^[\t ]*[0-9]\+[\t ]*//'
}


# Yields an int rather than something that could be in a “k/n” format.
# “0” if no data.
function get_clean_track_number_from_file {
    "$MMETA" '%T\n' "${1:?No file given.}" | sed 's:\/.*::g' | awk '{ print int($1) }'
}


function print_metafile_line_for_track {
    : "${1:?No file given.}"
    
    local -i n
    local title
    local raw_title
    
    # Track number. We just want a nonpadded integer.
    # It might be <n>/<k>, I think, hence the sed removing stuff.
    n=$(get_clean_track_number_from_file "$1")
    
    raw_title=$("$MMETA" -e '%t' "$1")
    if [ -z "$raw_title" ]
    then
        # Use filename as fallback to be able to differentiate tracks
        # if several have crappy metadata.
        raw_title=$(
            basename "$1" | sed -r '
                s/\.(mp3|flac)$//i
                s/[_ ]+/ /g
            '
        )
    fi
    
    title=$("$CAPITASONG" "$raw_title")
    
    printf '%-7d= %s\n' "$n" "$title"
}


# $1    Type (“mp3” or “flac”).
# $2    Name of external associative metadata array.
function print_metafile_content {
    local type=${1:?No type given.}
    
    if [ "$2" != t ]
    then
        local -n t=${2:?No array name given.}
    fi
    
    local file
    
    cat << _CONTENT_TOP_
# Edit this file, save, and close your editor.
# If this ZIP was not meant to be read,
# set “SKIP” to “y” to skip it.

SKIP        = n

ARTIST      = ${t[artist]}
ALBUMARTIST = ${t[albumartist]}
ALBUM       = ${t[album]}
YEAR        = ${t[year]}
GENRE       = ${t[genre]}

# <Track #> = <Title>
_CONTENT_TOP_

    while read -rd '' file
    do
        print_metafile_line_for_track "$file"
    done < <(
        find storage/"$type"/ -type f -iname "*.${type}" -print0
    ) | sort -V
    
    cat << '_CONTENT_BOTTOM_'

# If some tracks should have a different artist
# than ARTIST, you can add a line to override it.
# For example, to set “Some Guy” as artist for
# the 7th track, add (anywhere) a line like:
#
#       a7=Some guy
#
# (without the “#”)
# You can also set the same custom artist for
# several tracks in one line, using a list of
# track numbers and (optionally) intervals:
#
#       a3,5-8,13 = Another Artist
#
# This will set the artist for tracks 3, 5,
# 6, 7, 8 and 13.
_CONTENT_BOTTOM_
}


# Allow the user to edit metadata in the file "$METAFILE".
function edit_metafile {
    "${EDITOR[@]}" "$METAFILE"
}


# $1    A string like:
#   [aA] ([0-9]+ | [0-9]+-[0-9]+) (, ([0-9]+ | [0-9]+-[0-9]+) )*
# (spaces will be ignored)
#
# stdout →  Individual numbers referred to by the list, one per line.
#           For example, for the input “3,7-10,14”, the output will be:
#
#           3
#           7
#           8
#           9
#           10
#           14
function get_override_track_nums {
    : "${1:?No input given.}"
    
    local specs
    local res
    
    specs=$(
        sed -r '
            # Remove useless characters.
            s/[^0-9,-]//g
            
            # Simplify redundancies.
            s/,{2,}/,/g
            s/-{2,}/-/g
            
            # Remove leading and trailing commas.
            s/^,+//
            s/,+$//
            
            # Quit, ignoring subsequent lines.
            q
        ' <<< "$1"
    )
    
    res=$(seq 999 | cut -d $'\n' -f "$specs" 2> /dev/null)
    
    if [ "$res" ]
    then
        printf '%s\n' "$res"
    else
        warn 'Could not process track list “%s”. Ignoring.' "$specs"
    fi
}


# Update a given associative metadata array
# depending on the contents of the file "$METAFILE".
# Also store track titles in an indexed array of a given name.
#
# $1    Name of metadata associative array (should already be declared).
# $2    Name of a global track title indexed array
#       that will be created and filled here.
#
# Exits with status 0 if the user did not ask to skip this ZIP.
#                   1 if skipping was asked for.
function read_metafile {
    local -n t=${1:?No array name given.}
    
    unset -v "${2:?No track array name given.}"
    declare -ga "$2"
    
    # Avoid “circular name references”: declare a reference
    # only if needed.
    if [ "$2" != tracks ]
    then
        local -n tracks=$2
    fi
    
    local key
    local val
    local -i one_num_for_override
    local -i max=0
    
    while IFS='=' read -r key val
    do
        # Trim. I used to be able to do that by adding [ \t] to IFS
        # but if I want to allow spaces in artist-overriding
        # track-number lists I have to make sure only “=” can determine
        # the boundary between key and value.
        key=$(sed -r 's/^[ \t]+|[ \t]+$//g' <<< "$key")
        val=$(sed -r 's/^[ \t]+|[ \t]+$//g' <<< "$val")
    
        case "$key" in
            SKIP)
                if [ "$val" = y ]
                then
                    return 1
                fi
                ;;
                
            ARTIST)         t['artist']=$val;;
            ALBUMARTIST)    t['albumartist']=$val;;
            ALBUM)          t['album']=$val;;
            YEAR)           t['year']=$val;;
            GENRE)          t['genre']=$val;;
            
            [0-9]|[0-9][0-9]|[0-9][0-9][0-9]|[0-9][0-9][0-9][0-9])
                if [ "$key" -gt "$max" ]
                then
                    max=$key
                fi
                tracks[$key]=$val
                
                debug 'Track %d: %q' "$key" "$val"
                ;;
            
            # Artist override line.
            [aA]*[0-9]*)
                while read -r one_num_for_override
                do
                    t[a${one_num_for_override}]=$val
                    
                    debug 'Track %d custom artist: %q' "$one_num_for_override" "$val"
                done < <(get_override_track_nums "$key")
                ;;
            
            *)
                # Ignored line.
                ;;
        esac
    done < "$METAFILE"
    
    t['maxtrack']=$max
    
    return 0
}


# $1    Type (mp3, flac…).
# $2    Name of external associative array with fields:
#           artist
#           album
function display_record_info {
    local type=${1:-??}
    if [ "$2" != t ]
    then
        local -n t=${2:?No array name given.}
    fi
    
    cat << _INFO_

  ╭────────────────────────────────────────────╌╌┄┄┈┈
  │ ${TBOLD}Type:  ${TNORM}  ${type^^}
  │ ${TBOLD}Artist:${TNORM}  ${t[artist]:-??}
  │ ${TBOLD}Album: ${TNORM}  “${t[album]:-??}”
  ╰────────────────────────────────────────────╌╌┄┄┈┈

_INFO_
}


# $1    Current track, if available.
# $2    Total number of tracks, if available.
function display_progress {
    local n
    local max
    
    n=$(    awk '{ print int($0) }' <<< "$1")
    max=$(  awk '{ print int($0) }' <<< "$2")
    
    if [ "$n" -lt 1 ]
    then
        n='??'
    fi
    
    if [ "$max" -lt 1 ]
    then
        max='??'
    fi
    
    log 'Track %s of %s...' "$n" "$max"
}


# $1    Source audio file.
# $2    Destination file for the MP3 converted version.
function convert_to_mp3 {
    local src=${1:?No source file given.}
    local dest=${2:?No destination file given.}
    
    local size
    
    if "$CONV" -v 'quiet' -i "$src" \
            -acodec libmp3lame -ab "$CONVERTED_MP3_RATE" "$dest"
    then
        size=$(du -h "$dest" | cut -f 1)
        log 'Created “%s” (%s).' "$(basename "$dest")" "$size"
        return 0
    else
        err 'Failed to convert “%s”.' "$(basename "$src")"
        return 1
    fi
}


# $1    MP3 file to be tagged.
# $2    Track number.
# $3    Human-friendly song title.
# $4    Name of external metadata associative array.
function retag_mp3 {
    if [ "$4" != t ]
    then
        local -n t=${4:?No array name given.}
    fi
    
    local out
    local -a optns
    local -i safe_year
    
    optns=(
        --no-color
        --remove-all
        "${EYED3_ENCODING_OPT[@]}"
        
        --artist="$(get_artist_for_track "$2" t)"
        --album="${t[album]}"
        --title="${3:?No song title given.}"
        --track="${2:?No track number given.}"
        --track-total="${t[maxtrack]}"
        --genre="${t[genre]}"
    )
    
    safe_year=$(tr -cd '0-9' <<< "${t[year]}")
    
    if [ "$safe_year" ] && [ "$safe_year" -gt 0 ]
    then
        optns+=(
            -Y "$safe_year"
        )
    fi
    
    if out=$(
            eyeD3 "${optns[@]}" "${1:?No file given.}" 2>&1
        )
    then
        return 0
    else
        printf '%s\n' "$out" >&2
        error_while_tagging_mp3 "${optns[@]}"
        return 1
    fi
}


# $1    Music file to process.
# $2    Name of external associative metadata array about the album.
# $3    Name of external indexed track title array.
function process_one_source_file {
    local src=${1:?No source music file given.}
    
    if [ "$2" != t ]
    then
        local -n t=${2:?No array name given.}
    fi
    
    if [ "$3" != tracks ]
    then
        local -n tracks=${3:?No track array name given.}
    fi
    
    local -i track_number
    local title
    local mp3_file
    local type
    
    # Extension.
    type=${src##*.}
    # Lowercase.
    type=${type,,}
    
    track_number=$("$MMETA" '%T' "$src" | cut -d '/' -f 1 | sed 's/^0*//')
    # Fallback: Try to get the track number from the filename.
    : "${track_number:=$(
        # Get the first group of numbers.
        grep -o '[0-9]\+' <<< "$(basename "$src")" \
                | awk '{ print int($1); exit 0 }'
    )}"
    
    display_progress "$track_number" "${t[maxtrack]}"
    
    title=${tracks[$track_number]}
    
    debug 'Tagging “%s”... Title: “%s”' "$src" "$title"
    
    if [ "$type" = flac ]
    then
        retag_flac "$src" "$track_number" "$title" "$2"
        
        if [ "$CONVERT_TO_MP3" ]
        then
            mkdir -p storage/mp3/ || return
            
            mp3_file=storage/mp3/$(
                # Basename without extension, whatever it is.
                basename "$src" | sed 's/\.[^.]*$//'
            ).mp3
            
            convert_to_mp3 "$src" "$mp3_file" || return
        fi
    else
        # MP3; no conversion, just tagging the file.
        mp3_file=$src
    fi
    
    # Is there an MP3 to tag? If so, do it.
    if [ "$mp3_file" ]
    then
        retag_mp3 "$mp3_file" "$track_number" "$title" "$2"
    fi
}


function look_for_existing_cover {
    local maybe_cover
    
    maybe_cover=$(
        find . -regextype 'posix-extended' -type f -readable \
                -iregex '.*/cover\.(png|jpe?g|gif)' \
                -print -quit
    )
    
    if [ "$maybe_cover" ]
    then
        printf '%s\n' "$maybe_cover"
        return 0
    fi
    
    return 1
}


function process_and_move_existing_cover {
    local found_cover=${1:?No cover given.}
    
    local new_cover
    local lq_cover
    local dir_that_needs_cover
    
    log 'Found cover: %q' "$found_cover"
    
    if grep -iq '\.gif$' <<< "$found_cover"
    then
        # Woops, it's a GIF. Let's make a JPG.
        new_cover=${found_cover%.*}.jpg
        convert "$found_cover" "$new_cover" &&
        debug 'Converted into: %q' "$new_cover"
        # Remove the GIF now that we converted it.
        rm -- "$found_cover"
        found_cover=$new_cover
    fi
    
    # Create low-quality version.
    "$LQCOVER" "$found_cover" "$COVER_LQ_BASENAME"
    lq_cover=$(dirname "$found_cover")/${COVER_LQ_BASENAME}
    
    # Put the cover in each directory that might need it.
    for dir_that_needs_cover in storage/{flac,mp3}/
    do
        test -d "$dir_that_needs_cover" || continue
        
        # Copy HQ and LQ to the directory.
        cp -- "$found_cover" "$lq_cover" "$dir_that_needs_cover"/
    done
    
    # Now that the cover is safely stored alongside the tracks
    # for each format (MP3, FLAC), we can delete the original files
    # that stand in the working directory.
    rm -- "$found_cover" "$lq_cover"
}


# $1    Name of metadata associative array.
function clean_all_file_names {
    if [ "$1" != t ]
    then
        local -n t=${1:?No array name given.}
    fi
    
    local file
    local num
    local file_title
    local new_basename
    
    debug 'Renaming files...'
    
    for file in storage/*/*
    do
        test -r "$file" || continue
        
        if grep -Eiq '.\.(flac|mp3)$' <<< "$file"
        then
            file_title=$("$MMETA" '%t' "$file")
            
            # Get track number, turn invalid stuff to empty string.
            num=$("$MMETA" '%T' "$file" | cut -d '/' -f 1 | tr -cd '0-9')
            
            if [ "$num" ] && [ "$num" -gt 0 ]
            then
                # 01, 02… Zero padding (width according to number
                # of digits in the highest track number).
                num=$(printf "%0${#t[maxtrack]}d" "$num")
                new_basename=${num}_-_${file_title}.${file##*.}
            else
                new_basename=${file_title}.${file##*.}
            fi
        else
            # Not a flac or mp3 file; surely a cover or something.
            new_basename=$(basename "$file")
        fi
        
        my_renamer "$file" "$("$RENAME" <<< "${new_basename:?}")"
    done
}


function find_non_music_files {
    find . -regextype 'posix-extended' -type f \
            -iregex '.*\.(pdf|png|jpe?g|gif|txt|html|md|adoc|mov|avi|mp4|mkv)|.*/readme.*' \
            -not -iregex '.*/cover\.(png|jpe?g|gif)' \
            -not -name "${COVER_LQ_BASENAME:?}" \
            -print0
}


function apply_cover_if_we_got_one {
    local type=${1:?No music type given.}
    
    local cov_file=storage/${type}/${COVER_LQ_BASENAME:?}
    
    if [ -r "$cov_file" ]
    then
        log 'Applying the cover art to files...'
        
        "$SETCOVER" storage/"$type"/ "$cov_file" > /dev/null
        
        if [ "$type" = flac ] && [ "$CONVERT_TO_MP3" ]
        then
            # Also need to apply the cover to the converted version.
            "$SETCOVER" storage/mp3/ "$cov_file" > /dev/null
        fi
    fi
}


function get_and_store_other_files {
    local other
    
    while read -rd '' other
    do
        # Skip nonexistent.
        test -r "$other" || continue
        # Skip the metafile.
        test "$other" -ef "$METAFILE" && continue
        
        mkdir -p -- storage/other/ &&
        cp -- "$other" storage/other/ &&
        log 'Found additional file “%s”.' "$(basename "$other")"
    done < <(find_non_music_files)
}


# $1    File from which metadata is to be initialized.
# $2    Name used to create a global metadata associative array.
#       The following fields will be initialized:
#
#           artist
#           albumartist
#           album
#           year
#           genre
function init_metadata {
    : "${1:?No file given.}"
    : "${2:?No array name given.}"
    
    if [ ! -r "$1" ] || [ -d "$1" ]
    then
        err 'Cannot get music metadata from “%s”.' "$1"
        return 1
    fi
    
    # Declare the array that will be used to make the metadata
    # available to the exterior of the function.
    unset -v "$2"
    declare -gA "$2" || return
    
    if [ "$2" != t ]
    then
        # Use a local handle to manipulate the array.
        local -n t=$2
    fi
    
    t[artist]=$("$CAPITASONG" "$("$MMETA" '%a' "$1")")
    t[albumartist]=${t[artist]}
    t[album]=$("$CAPITASONG" "$("$MMETA" '%A' "$1")")
    t[year]=$("$MMETA" -e '%y' "$1")
    t[genre]=$("$MMETA" '%g' "$1")
    
    if [ "${t[genre]}" = "$MMETA_PLACEHOLDER" ]
    then
        t[genre]=$(try_to_guess_genre "${t[albumartist]}")
        # If the guessing failed, revert to the placeholder.
        : "${t[genre]:=$MMETA_PLACEHOLDER}"
    fi
}


# $1    Name of external associative metadata array about the album.
#       Used for fields “albumartist” and “album”.
function compute_final_dir_path {
    if [ "$1" != t ]
    then
        local -n t=${1:?No array name given.}
    fi
    
    local artist_dirname
    local album_dirname
    
    artist_dirname=$("$RENAME" <<< "${t[albumartist]}")
    album_dirname=$("$RENAME" <<< "${t[album]}")
    
    printf '%s\n' "${DIR_M:?}/${artist_dirname:?}/${album_dirname:?}"
}


# $1    MP3 file.
# $2    Track number to apply.
function set_track_number_for_mp3 {
    : "${1:?No file given.}"
    : "${2:?No track number given.}"
    
    local -a optns
    
    optns=(
        --to-v2.4
        --no-color
        --track="$2"
    )
    
    eyeD3 "${optns[@]}" "$1" &> /dev/null
}


# $1    FLAC file.
# $2    Track number to apply.
function set_track_number_for_flac {
    : "${1:?No file given.}"
    : "${2:?No track number given.}"
    
    local -a optns
    
    optns=(
        --dont-use-padding
        --remove-tag=TRACKNUMBER
        --set-tag="TRACKNUMBER=${2}"
    )
    
    metaflac "${optns[@]}" "$1"
}


# $1    File. MP3 or FLAC, with clear extension.
# $2    Track number to apply.
function set_track_number_for_file {
    : "${1:?No file given.}"
    : "${2:?No track number given.}"
    
    local ext
    
    ext=${1##*.}
    ext=${ext,,}
    
    case "$ext" in
        mp3)
            set_track_number_for_mp3 "$@"
            ;;
        
        flac)
            set_track_number_for_flac "$@"
            ;;
        
        *)
            # Unknown type.
            return 1
            ;;
    esac
}


# $1    Type (mp3 / flac).
function music_file_precleaning {
    local type=${1:?No music type given.}
    
    local f
    # Track numbers already used by a track.
    local -A used_numbers
    # Files that need a track number, either because they have none
    # or because the one they use is used by another file.
    local -a need_numbers
    local -i num
    
    # I think “sort -z” appeared quite late, so let’s not take any risk
    # and start with making sure there are no newlines in filenames.
    while read -rd '' f
    do
        my_renamer "$f" "$(basename "$f" | tr -d '\n')"
    done < <(
        find storage/"$type"/ -type f -iname "*.${type}" -print0
    )
    
    while read -r f
    do
        num=$(get_clean_track_number_from_file "$f")
        
        # Must be valid AND not already taken.
        if [ "$num" -ge 1 ] && [ ! "${used_numbers[$num]}" ]
        then
            used_numbers[$num]=1
        else
            if [ "${used_numbers[$num]}" ]
            then
                debug '“%s” needs a new track number (%d already used).' "$(basename "$f")" "$num"
            else
                debug '“%s” has no track number.' "$(basename "$f")"
            fi
            need_numbers+=("$f")
        fi
    done < <(
        find storage/"$type"/ -type f -iname "*.${type}" | sort -V
    )
    
    # Let’s fill the gaps!
    for f in "${need_numbers[@]}"
    do
        # We need to find the smallest available number.
        num=1
        while [ "${used_numbers[$num]}" ]
        do
            ((num++)) || true
        done
        
        # Set it in the metadata!
        if set_track_number_for_file "$f" "$num"
        then
            used_numbers[$num]=1
            debug 'Set track number of “%s” to %d.' "$(basename "$f")" "$num"
        else
            warn 'Could not set track number of “%s”.' "$(basename "$f")"
        fi
    done
    
    return 0
}


function process_one_music_zip {
    local archive=${1:?No ZIP archive given.}
    
    local sample_file
    local type
    local src
    local final_dir
    
    unzip "$(basename "$archive")" || return
    
    sample_file=$(get_sample_file)
    type=$(get_record_format "$sample_file")
    
    if [ -z "$type" ]
    then
        err 'Failed to get a sample file. Skipping this ZIP.'
        return 1
    fi
    
    init_metadata "$sample_file" _meta
    display_record_info "$type" _meta
    
    # Create a directory to store the music per type.
    # This is not the final location, as the user did not even
    # get a chance to revise the metadata (which is used
    # to choose the directory names).
    mkdir -p -- storage/"$type"/ || return
    find . -type f -iname "*.${type}" -print0 \
            | xargs -0 -I {} mv {} storage/"$type"/ ||
    return
    
    music_file_precleaning "$type"
    
    # Initialise metadata, show it to the user, allow corrections,
    # read it back again.
    print_metafile_content "$type" _meta > "$METAFILE"
    edit_metafile
    if ! read_metafile _meta _tracks
    then
        log 'Skipping, as asked by the user.'
        return 0
    fi

    for src in storage/mp3/*.mp3 storage/flac/*.flac
    do
        test -r "$src" || continue
        
        process_one_source_file "$src" _meta _tracks
    done
    
    found_cover=$(look_for_existing_cover)
    
    if [ "$found_cover" ]
    then
        process_and_move_existing_cover "$found_cover"
    else
        # Call script to try to download a cover.
        warn 'No cover art found in the archive. Attempting to find one online...'
        "$COVERS" storage/
    fi
    
    apply_cover_if_we_got_one "$type"
    get_and_store_other_files
    clean_all_file_names _meta
    
    final_dir=$(compute_final_dir_path _meta)
    
    log 'Moving the files to “%s”...' "$final_dir"
    
    if mkdir -p -- "$final_dir" &&
        rsync -au -- storage/ "$final_dir"/
    then
        clean_hierarchy_if_needed "$final_dir"
        
        log 'All done for this ZIP.'
        rm -v -- "$archive"
    else
        log 'Refrained from deleting the original ZIP because of errors.'
    fi
}

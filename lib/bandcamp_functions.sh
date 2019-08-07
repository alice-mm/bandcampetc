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
    
    printf "%s%s ${2}\n" "$prog" "$1" "${@:3}"
}

# $1    Printf-style format string.
# $2…n  Arguments for printf.
function log {
    _f_log '' "$@"
}

# $1    Printf-style format string.
# $2…n  Arguments for printf.
function warn {
    _f_log " ${TYEL}Warning:${TNORM}" "$@" >&2
}

# $1    Printf-style format string.
# $2…n  Arguments for printf.
function err {
    _f_log " ${TRED}Error:${TNORM}" "$@" >&2
}


# $1    Path to target file.
# $2    New basename.
function my_renamer {
    local old=${1:?}
    local new
    
    new=$(dirname "$1")/${2:?}
    
    if ! [ "$old" -ef "$new" ]
    then
        mv -n -- "$old" "$new" &&
        printf ' “%s” → “%s”\n' "$(basename "$old")" "$2"
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


# $1    FLAC file to retag.
# $2    Human-friendly song title.
# $3    Name of an associative array with fields:
#           artist
#           albumartist
#           album
#           genre
#           year
function retag_flac {
    : "${1:?No file given.}"
    : "${2:?No song title given.}"
    : "${3:?No array name given.}"
    
    if [ "$3" != t ]
    then
        local -n t=$3
    fi
    
    local -a optns
    
    optns=(
        --dont-use-padding
        
        --remove-tag=TITLE
        --remove-tag=ARTIST
        --remove-tag=ALBUMARTIST
        --remove-tag=ALBUM
        --remove-tag=GENRE
        --remove-tag=DATE
        
        --set-tag="TITLE=${2}"
        --set-tag="ARTIST=${t[artist]}"
        --set-tag="ALBUMARTIST=${t[albumartist]}"
        --set-tag="ALBUM=${t[album]}"
        --set-tag="GENRE=${t[genre]}"
        --set-tag="DATE=${t[year]}"
    )
    
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
    # The most frequent answer (ignoring “$MMETA_PLACEHOLDER”) wins.
    find "$DIR_M"/"$("$RENAME" <<< "$1")"/ -type f \
            '(' -iname '*.mp3' -or -iname '*.flac' ')' 2> /dev/null \
            | shuf | head -5 \
            | xargs --no-run-if-empty "$MMETA" '%g\n' 2> /dev/null \
            | grep -vxF -- "$MMETA_PLACEHOLDER" | sort | uniq -c | sort -k1,1nr | head -1 \
            | sed $'s/^[\t ]*[0-9]\+[\t ]*//'
}


function print_metafile_line_for_track {
    : "${1:?No file given.}"
    
    local -i n
    local title
    
    # Track number. We just want a nonpadded integer.
    # It might be <n>/<k>, I think, hence the sed removing stuff.
    n=$(
        "$MMETA" '%T\n' "$1" | sed 's:\/.*::g' | awk '{ print int($1) }'
    )
    title=$("$CAPITASONG" "$("$MMETA" '%t' "$1")")
    
    printf '%-7d= %s\n' "$n" "$title"
}


# $1    Type (“mp3” or “flac”).
# $2    Name of external associative metadata array.
function print_metafile_content {
    local type=${1:?No type given.}
    local -n t=${2:?No array name given.}
    
    local file
    
    cat << _CONTENT_
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
_CONTENT_

    while read -rd '' file
    do
        print_metafile_line_for_track "$file"
    done < <(
        find storage/"$type"/ -type f -iname "*.${type}" -print0
    ) | sort -V
}


# Allow the user to edit metadata in the file "$METAFILE".
function edit_metafile {
    "${EDITOR[@]}" "$METAFILE"
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
    local -i max=0
    
    while IFS=$' \t\n=' read -r key val
    do
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
            
            [0-9]|[0-9][0-9]|[0-9][0-9][0-9])
                if [ "$key" -gt "$max" ]
                then
                    max=$key
                fi
                tracks[$key]=$val
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
    local -n t=${2:?No array name given.}
    
    cat << _INFO_

  ╭────────────────────────────────────────────╌╌┄┄┈┈
  │ ${TBOLD}Type:  ${TNORM}  ${type^^}
  │ ${TBOLD}Artist:${TNORM}  ${t[artist]:-??}
  │ ${TBOLD}Album: ${TNORM}  “${t[album]:-??}”
  ╰────────────────────────────────────────────╌╌┄┄┈┈

_INFO_
}


function display_progress {
    local n
    local max
    
    if [ "$1" ] && [ "$1" != 0 ]
    then
        n=$1
    else
        n='??'
    fi
    
    if [ "$2" ] && [ "$2" != 0 ]
    then
        max=$2
    else
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
    local -n t=${4:?No array name given.}
    local -a optns
    
    optns=(
        --no-color
        --remove-all
        --no-tagging-time-frame
        --set-encoding=utf8
        
        --artist="${t[artist]}"
        --album="${t[album]}"
        --title="${3:?No song title given.}"
        --track="${2:?No track number given.}"
        --track-total="${t[maxtrack]}"
        --genre="${t[genre]}"
        --year="${t[year]}"
    )
    
    if eyeD3 "${optns[@]}" "${1:?No file given.}" &> /dev/null
    then
        return 0
    else
        error_while_tagging_mp3 "${optns[@]}"
        return 1
    fi
}


# $1    Music file to process.
# $2    Name of external associative metadata array about the album.
# $3    Name of external indexed track title array.
function process_one_source_file {
    local src=${1:?No source music file given.}
    local -n t=${2:?No array name given.}
    local -n tracks=${3:?No track array name given.}
    
    local -i track_number
    local title
    local mp3_file
    
    track_number=$("$MMETA" '%T' "$src" | cut -d '/' -f 1)
    # Fallback: Try to get the track number from the filename.
    : "${track_number:=$(
        # Get the first group of numbers.
        grep -o '[0-9]\+' <<< "$(basename "$src")" \
                | awk '{ print int($1); exit 0 }'
    )}"
    
    display_progress "$track_number" "${t[maxtrack]}"
    
    title=${tracks[track_number]}
    
    if [ "$type" = flac ]
    then
        retag_flac "$src" "$title" "$2"
        
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
    
    for maybe_cover in {cover,COVER}.{jpg,jpeg,png,gif,JPG,JPEG,PNG,GIF}
    do
        if [ -r "$maybe_cover" ]
        then
            printf '%s\n' "$maybe_cover"
            return 0
        fi
    done
    
    return 1
}


function process_and_move_existing_cover {
    local found_cover=${1:?No cover given.}
    
    local new_cover
    local dir_that_needs_cover
    
    log 'Found cover: %q' "$found_cover"
    
    if grep -iq '\.gif$' <<< "$found_cover"
    then
        # Woops, it's a GIF. Let's make a JPG.
        new_cover=${found_cover%.*}.jpg
        convert "$found_cover" "$new_cover" &&
        log 'Converted into: %q' "$new_cover"
        found_cover=$new_cover
    fi
    
    # Create low-quality version.
    "$LQCOVER" "$found_cover" "$COVER_LQ_BASENAME"
    
    # Put the cover in each directory that might need it.
    for dir_that_needs_cover in storage/{flac,mp3}/
    do
        test -d "$dir_that_needs_cover" || continue
        
        cp -- "$found_cover" "$COVER_LQ_BASENAME" "$dir_that_needs_cover"/
    done
    
    # Now that the cover is safely stored alongside the tracks
    # for each format (MP3, FLAC), we can delete the original files
    # that stand in the working directory.
    rm -- "$found_cover" "$COVER_LQ_BASENAME"
}


# $1    Name of metadata associative array.
function clean_all_file_names {
    local -n t=${1:?No array name given.}
    
    local file
    local num
    local file_title
    local new_basename
    
    log 'Renaming files...'
    
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
            -iregex '.*\.(pdf|png|jpe?g|gif|txt|html|md)|.*/readme.*' \
            -not -iregex '.*/cover(_lq)?\.(png|jpe?g|gif)' \
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
function init_metadata {
    : "${1:?No file given.}"
    : "${2:?No array name given.}"
    
    # Declare the array that will be used to make the metadata
    # available to the exterior of the function.
    unset -v "$2"
    declare -gA "$2" || return
    # Use a local handle to manipulate the array.
    local -n t=$2
    
    t[artist]=$("$CAPITASONG" "$("$MMETA" '%a' "$1")")
    t[albumartist]=${t[artist]}
    t[album]=$("$CAPITASONG" "$("$MMETA" '%A' "$1")")
    t[year]=$("$MMETA" '%y' "$1")
    t[genre]=$("$MMETA" '%g' "$1")
    
    if [ "${t[genre]}" = "$MMETA_PLACEHOLDER" ]
    then
        t[genre]=$(try_to_guess_genre "${t[albumartist]}")
        # If the guessing failed, revert to the placeholder.
        : "${t[genre]:=$MMETA_PLACEHOLDER}"
    fi
}


# $1    Name of external associative metadata array about the album.
function compute_final_dir_path {
    local -n t=${1:?No array name given.}
    
    local artist_dirname
    local album_dirname
    
    artist_dirname=$("$RENAME" <<< "${t[albumartist]}")
    album_dirname=$("$RENAME" <<< "${t[album]}")
    
    printf '%s\n' "${DIR_M:?}/${artist_dirname:?}/${album_dirname:?}"
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
    
    mkdir -p -- "$final_dir" &&
    rsync -au -- storage/ "$final_dir"/ &&
    log 'All done for this ZIP.' &&
    rm -v -- "$archive"
}

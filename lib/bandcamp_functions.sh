#! /usr/bin/env bash


# $1    Path to target file.
# $2    New basename.
function my_renamer {
    local old=$1
    local new=$(dirname "$1")/${2}
    
    if ! [ "$old" -ef "$new" ]
    then
        mv -n -- "$old" "$new" &&
        printf '  “%q” → “%q”\n' "$(basename "$old")" "$2"
    fi
}


function mp3_or_flac_in_zip {
    unzip -l "${1:?No archive given.}" | grep -iqE '.\.(flac|mp3)$'
}


# Find out if there is MP3 or FLAC in or below the working directory.
# If both types are present, one will be kind of randomly ignored.
function get_record_format {
    local sample_file
    local ext
    
    sample_file=$(
        find -iregex '.*[^/]\.\(flac\|mp3\)' -print -quit
    )
    
    ext=${sample_file##*.}
    
    printf '%s\n' "${ext,,}"
}


# $1    FLAC file to retag.
# $2    Name of an associative array with fields:
#           title
#           artist
#           albumartist
#           album
#           genre
#           year
function retag_flac {
    local -a retag_flac_optns
    local -n retag_flac_data=${2:?No data given.}
    
    retag_flac_optns=(
        --dont-use-padding
        
        --remove-tag=TITLE
        --remove-tag=ARTIST
        --remove-tag=ALBUMARTIST
        --remove-tag=ALBUM
        --remove-tag=GENRE
        --remove-tag=DATE
        
        --set-tag="TITLE=${retag_flac_data[title]}"
        --set-tag="ARTIST=${retag_flac_data[artist]}"
        --set-tag="ALBUMARTIST=${retag_flac_data[albumartist]}"
        --set-tag="ALBUM=${retag_flac_data[album]}"
        --set-tag="GENRE=${retag_flac_data[genre]}"
        --set-tag="DATE=${retag_flac_data[year]}"
    )
    
    metaflac "${retag_flac_optns[@]}" "${1:?No file given.}"
}


function error_while_tagging_mp3 {
    cat >&2 << _ERR_

$(basename "$0"): Error while tagging “${dest}”. Parameters:
  --artist="${metaartist}"
  --album="${metaalbum}"
  --title="${title}"
  --track="${track_number}"
  --track-total="${metamaxtrack}"
  --genre="${metagenre}"
  --year="${metayear}"
EyeD3 exit status: $?

_ERR_
}


# Try to look for music of the same artist to find out what the genre is.
# If something suitable is found, it is placed in the “metagenre” variable.
# The “albumartist” variable is used as the base for the guess.
function try_to_guess_genre {
    local guess
    
    guess=$(
        # Get a few random files and try to see what their genre is.
        # Then, the most frequent answer (ignoring “$MMETA_PLACEHOLDER”) wins.
        find "$DIR_M"/"$albumartist"/ -type f \
                '(' -iname '*.mp3' -or -iname '*.flac' ')' 2> /dev/null \
                | shuf | head -5 \
                | xargs --no-run-if-empty "$MMETA" '%g\n' 2> /dev/null \
                | grep -vxF -- "$MMETA_PLACEHOLDER" | sort | uniq -c | sort -k1,1nr | head -1 \
                | sed $'s/^[\t ]*[0-9]\+[\t ]*//'
    )
    
    if [ "$guess" ]
    then
        metagenre="$guess"
    fi
}


# Create the file "$METAFILE" with default metadata.
# Need a lot of variables to be initialized.
function write_metafile {
    local n
    local title
    
    {
        cat << _CONTENT_
# Edit this file, save, and exit your editor.
# If this zip was not meant to be imported,
# set “SKIP” to “y”.

SKIP        = n

ARTIST      = ${metaartist}
ALBUMARTIST = ${metaalbumartist}
ALBUM       = ${metaalbum}
YEAR        = ${metayear}
GENRE       = ${metagenre}

# <Track #> = <Title>
_CONTENT_

        while read -rd '' file
        do
            # Track number. We just want a nonpadded integer.
            # It might be <n>/<k>, I think, hence the sed removing stuff.
            n=$(
                "$MMETA" '%T\n' "$file" | sed 's:\/.*::g' | awk '{ print int($1) }'
            )
            title=$(
                "$CAPITASONG" "$("$MMETA" '%t' "$file")"
            )
            
            printf '%-7d= %s\n' "$n" "$title"
        done < <(
            find "$artist"/"$album"/"$type"/ -type f -iname "*.$type" -print0
        ) | sort -V
    } > "$METAFILE"
}


# Allow the user to edit metadata in the file "$METAFILE".
function edit_metafile {
    "${EDITOR[@]}" "$METAFILE"
}


# Update a few variables depending on the contents of the file "$METAFILE".
#
# → 0 if the user did not ask to skip this ZIP.
#   1 if skipping was asked for.
function read_metafile {
    local key
    local val
    
    unset -v metatracks metaartist metaalbumartist metaalbum \
            metayear metagenre
    
    while IFS=$' \t\n=' read -r key val
    do
        case "$key" in
            SKIP)
                if [ "$val" = 'y' ]
                then
                    return 1
                fi
                ;;
                
            ARTIST)         metaartist=$val;;
            ALBUMARTIST)    metaalbumartist=$val;;
            ALBUM)          metaalbum=$val;;
            YEAR)           metayear=$val;;
            GENRE)          metagenre=$val;;
            
            [0-9]|[0-9][0-9]|[0-9][0-9][0-9])
                            metatracks[key]=$val;;
        esac
    done < "$METAFILE"
    
    # Highest track number.
    metamaxtrack=$(
        xargs -n 1 printf '%s\n' <<< "${!metatracks[@]}" \
                | sort -rn | head -1
    )
    
    : "${metamaxtrack:=0}"
    
    return 0
}

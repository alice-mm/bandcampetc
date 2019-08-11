#! /usr/bin/env bash


# Print "flac" or "mp3", or nothing if unrecognized type.
# $1 as input.
function f_gettype {
    : "${1:?}"

    local ext
    local mime
    
    ext=${1##*.}
    ext=${ext,,}
    
    mime=$(
        file -b --mime-type "$1"
    )
    
    case "$ext" in
        mp3)
            if [ "$mime" = audio/mpeg ] ||
                [ "$mime" = application/octet-stream ]
            then
                echo mp3
            fi
            ;;
        
        flac)
            if [ "$mime" = audio/x-flac ]
            then
                echo flac
            fi
            ;;
        
        *)
            # Unknown type.
            ;;
    esac
}


# $1    One MP3 file to be tagged.
# $2    A picture to be used as a FRONT_COVER, or an empty string if the
#       images must be removed from the file.
function f_tag {
    printf '%s: Removing images from “%s”...\n' "$(basename "$0")" "$1"
    
    if eyeD3 --no-color --remove-images "$1" 2>&1 > /dev/null | sed 's/^/eyeD3: /'
    then
        echo "OK"
    else
        echo "Error? ($?)"
        ((glob_errors++))
    fi
    
    if [ "$2" ]
    then
        printf '%s: “%s” → “%s”...\n' "$(basename "$0")" "$2" "$1"
        
        if eyeD3 --no-color --add-image="$2":FRONT_COVER "$1" 2>&1 > /dev/null | sed 's/^/eyeD3: /'
        then
            echo "OK"
        else
            echo "Error? ($?)"
            ((glob_errors++))
        fi
    fi
}


# $1    One FLAC file to be tagged.
# $2    A picture to be used as a FRONT_COVER, or an empty string if the
#       images must be removed from the file.
function f_tag_flac {
    printf '%s: Removing images from “%s”...\n' "$(basename "$0")" "$1"
    
    # For all block numbers coresponding to front covers.
    nb_removed=0
    while read -r block_num
    do
        if metaflac --dont-use-padding --remove \
                --block-number="${block_num}" "$1" 2>&1 > /dev/null \
                | sed 's/^/metaflac: /'
        then
            echo 'OK'
            ((nb_removed++))
        else
            echo "Error? ($?)"
            ((glob_errors++))
        fi
    done < <(
        # There are several blocks, each with a number, and the number is a few
        # lines above the "type: 3 (Cover (front))" part.
        metaflac --list "$1" \
                | tac \
                | sed -n '
                    # From "blahblah cover front" to "metadata block <number>",
                    # print the numbers.
                    /^  type: 3 (Cover (front))$/,/^METADATA block #[0-9]\+$/ s/METADATA block #\([0-9]\+\)/\1/p
                ' \
                | grep -x '[0-9]\+'
    )
    
    if [ "$2" ]
    then
        printf '%s: “%s” → “%s”...\n' "$(basename "$0")" "$2" "$1"
        if metaflac --import-picture-from "$2" "$1" 2>&1 > /dev/null | sed 's/^/metaflac: /'
        then
            echo 'OK'
        else
            echo "Error? ($?)"
            ((glob_errors++))
        fi
    fi
}


# $1    Target.
# $2    Picture.
function f_single_file {
    local type
    
    type=$(f_gettype "$1")
    
    if [ ! "$type" ]
    then
        echo "$(basename "$0"): Error: \"$1\" does not look like a MP3 or FLAC file." >&2
        exit 6
    fi
    
    case "$type" in
        mp3)
            f_tag "$1" "$2"
            ;;
        
        flac)
            if [ "$METAFLAC" ]
            then
                f_tag_flac "$1" "$2"
            else
                echo "$(basename "$0"): Error: Cannot tag \"$1\" because metaflac does not seem to be installed." >&2
            fi
            ;;
        
        *)
            printf '%s: Error: Type “%s” not fully supported.\n' \
                    "$(basename "$0")" "$type" >&2
            ;;
    esac
}

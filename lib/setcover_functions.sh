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
            if [ "$mime" = audio/x-flac ] ||
                [ "$mime" = audio/flac ]
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

    # At some point, eyeD3 changed that option’s name
    # and entirely dropped the support for the former name.
    local rm_opt
    if eyeD3 --help 2> /dev/null | grep -q -- '--remove-all-images'
    then
        rm_opt='--remove-all-images'
    else
        rm_opt='--remove-images'
    fi

    if eyeD3 --no-color "$rm_opt" "$1" 2>&1 > /dev/null | sed 's/^/eyeD3: /'
    then
        echo "OK"
    else
        echo "Error: $?"
        return 1
    fi

    if [ "$2" ]
    then
        printf '%s: “%s” → “%s”...\n' "$(basename "$0")" "$2" "$1"

        if eyeD3 --no-color --add-image="$2":FRONT_COVER "$1" 2>&1 > /dev/null | sed 's/^/eyeD3: /'
        then
            echo "OK"
        else
            echo "Error: $?"
            return 1
        fi
    fi
}


# $1    FLAC file.
# stdout →  comma-separated list of block numbers corresponding
#           to PICTURE type metadata blocks.
function get_flac_cover_front_block_nums {
    local flac_file=${1:?No file given.}

    local out
    out=$(metaflac --list --block-type PICTURE "$flac_file") || return

    out=$(
        grep -Ex 'METADATA block #[0-9]+' <<< "$out" | tr -cd '0-9\n'
    )

    if [ "$out" ]
    then
        # Print as comma-separated list.
        printf '%s\n' "${out//$'\n'/,}"
    fi

    # Be happy even if no block found.
    # What matters is that “metaflac” did not crash.
    return 0
}


# $1    One FLAC file to be tagged.
# $2    A picture to be used as a FRONT_COVER, or an empty string if the
#       images must be removed from the file.
function f_tag_flac {
    : "${1:?No file given.}"

    local block_nums

    printf '%s: Removing images from “%s”...\n' "$(basename "$0")" "$1"

    block_nums=$(get_flac_cover_front_block_nums "$1") || return

    if [ "$block_nums" ]
    then
        if metaflac --dont-use-padding --remove \
                --block-number="$block_nums" "$1" 2>&1 > /dev/null \
                | sed 's/^/metaflac: /'
        then
            echo 'OK'
        else
            echo "Error: $?"
            return 1
        fi
    fi

    if [ "$2" ]
    then
        printf '%s: “%s” → “%s”...\n' "$(basename "$0")" "$2" "$1"
        if metaflac --dont-use-padding --import-picture-from "$2" "$1" 2>&1 > /dev/null \
                | sed 's/^/metaflac: /'
        then
            echo 'OK'
        else
            echo "Error: $?"
            return 1
        fi
    fi
}


# $1    Target.
# $2    Picture.
function f_single_file {
    local type

    type=$(f_gettype "$1")

    if [ -z "$type" ]
    then
        printf '%s: Error: “%s” does not look like an MP3 or FLAC file.\n' \
                "$(basename "$0")" "$1" >&2
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

# Set music directory. Just remove these lines and
# hard-code a path if you want to use something else:
#
#   readonly DIR_M=/home/you/some/dir
#
# English last to use as fallback if none exist:
for one_dir in ~/{Musique,Música,Musik,Muziek,Музыка,Muzyka,Musica,Müzik,Music}
do
    if [ -d "$one_dir" ]
    then
        break
    fi
    
    # Try in lowercase.
    if [ -d "${one_dir,,}" ]
    then
        one_dir=${one_dir,,}
        break
    fi
done
readonly DIR_M=$one_dir

# Set to non empty value to convert FLAC files to MP3.
# I used to keep everything in both formats, and then ran out of space.
# Now I convert to MP3 on the fly when putting music on my phone or whatever.
CONVERT_TO_MP3=''

# EDITOR is a text editor command with options, in an indexed array.
#
# Example:
#
#   EDITOR=(geany --new-instance)
#
# Make sure the command is blocking. The script should wait until
# you close the editor. Hence the fact that I use Geany’s “-i” option,
# to prevent it from using an existing instance.
unset -v EDITOR
#readonly EDITOR=(nano -S)
#readonly EDITOR=(vi)
#readonly EDITOR=(mousepad)
#readonly EDITOR=(leafpad)
#readonly EDITOR=(gedit)
readonly EDITOR=(geany -i)

# avconv replaced ffmpeg in Ubuntu's repositories. The options I use exist
# for both programs, so there's no real difference in this use case, I guess.
# Edit: It's actually a bit more complicated than this. Ffmpeg still exists and
# seems better.
#
# See: https://stackoverflow.com/a/9477756
#
# Starting with Ubuntu 16, it's probably better to use ffmpeg.
#
# Note that you won't need any of these if you do not try to convert FLAC files
# into MP3 files, by the way.
readonly CONV=ffmpeg
#readonly CONV=avconv

# What the MMETA script gives when asked for an unavailable information.
readonly MMETA_PLACEHOLDER='Unknown'
# Basename for low quality cover arts.
readonly COVER_LQ_BASENAME='cover_lq.jpg'
# Given to Lame when creating MP3 files from HQ files.
readonly CONVERTED_MP3_RATE=128k
# Set to non empty value to activate debug logs.
PRINT_DEBUG=''

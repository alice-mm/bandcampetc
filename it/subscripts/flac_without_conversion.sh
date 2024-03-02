#! /usr/bin/env bash

set -ex


cp -v it/assets/fake_album_flac_version.zip ~/Downloads/
./bin/bandcamp -d


test "$(
    find ~/Music/ -type f | sort -V
)" = "$(
    cat << '_EXPECTATIONS_'
/root/Music/alice/fake_album/1_-_one.flac
/root/Music/alice/fake_album/2_-_two.flac
/root/Music/alice/fake_album/3_-_three.flac
/root/Music/alice/fake_album/4_-_four.flac
/root/Music/alice/fake_album/cover.png
/root/Music/alice/fake_album/cover_lq.jpg
_EXPECTATIONS_
)"

: All FLAC files should have at least a given size.
test -z "$(
    du -b ~/Music/alice/fake_album/*.flac | akw '$1 < 5000'
)"

test "$(
    sha1sum ~/Music/alice/fake_album/cover.png | cut -d ' ' -f 1
)" = 48d618c6b7889746dab52fa31a19f6ae622a4604

test "$(
    ./bin/mmeta '%a %t %A %T %g %y\n' ~/Music/alice/fake_album/*.flac
)" = "$(
    cat << '_EXPECTATIONS_'
Alice One Fake Album 1 Experimental 2019
Alice Two Fake Album 2 Experimental 2019
Alice Three Fake Album 3 Experimental 2019
Alice Four Fake Album 4 Experimental 2019
_EXPECTATIONS_
)"

: Cover test.
for flac_file in ~/Music/alice/fake_album/*.flac
do
    metaflac --export-picture-to=picdump "$flac_file"

    test "$(file picdump)" = 'picdump: PNG image data, 250 x 250, 1-bit colormap, non-interlaced'

    test "$(
        sha1sum picdump | cut -d ' ' -f 1
    )" = "$(
        sha1sum ~/Music/alice/fake_album/cover_lq.jpg | cut -d ' ' -f 1
    )"
done

test -z "$(find ~/Downloads/ -type f)"

#! /usr/bin/env bash

set -evx


cp -v it/assets/fake_album_mp3_version.zip ~/Downloads/
./bin/bandcamp -d


test "$(
    find ~/Music/ -type f | sort -V
)" = "$(
    cat << '_EXPECTATIONS_'
/root/Music/alice/fake_album/1_-_one.mp3
/root/Music/alice/fake_album/2_-_two.mp3
/root/Music/alice/fake_album/3_-_three.mp3
/root/Music/alice/fake_album/4_-_four.mp3
/root/Music/alice/fake_album/cover.png
/root/Music/alice/fake_album/cover_lq.jpg
_EXPECTATIONS_
)"

test "$(
    sha1sum ~/Music/alice/fake_album/cover.png | cut -d ' ' -f 1
)" = 48d618c6b7889746dab52fa31a19f6ae622a4604

: MP3 metadata.
eyeD3 --no-color ~/Music/alice/fake_album/*.mp3

test "$(
    ./bin/mmeta '%a %t %A %T %g %y\n' ~/Music/alice/fake_album/*.mp3
)" = "$(
    cat << '_EXPECTATIONS_'
Alice One Fake Album 1/4 Experimental 2019
Alice Two Fake Album 2/4 Experimental 2019
Alice Three Fake Album 3/4 Experimental 2019
Alice Four Fake Album 4/4 Experimental 2019
_EXPECTATIONS_
)"

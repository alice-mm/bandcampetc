#! /usr/bin/env bash

set -evx

# shellcheck source=../../lib/bandcamp_functions.sh
. lib/bandcamp_functions.sh


( clean_hierarchy;          true ) && exit 1
( clean_hierarchy '';       true ) && exit 1
( clean_hierarchy '' foo;   true ) && exit 1

! clean_hierarchy /does/not/exist/of/course

tdir=$(mktemp -d "${TMPDIR:-/tmp}"/bandcamp-test-cleaning-XXXXXXXX)
test -d "${tdir:?}"

mkdir -p "$tdir"/foo/bar/plop/{aa,.hbb} "$tdir"/foo/yo
touch "$tdir"/foo/bar/plop/{aa/,.hbb/,}{f1,f2,f3,.hf1,.hf2}

! clean_hierarchy "$tdir"/foo
! clean_hierarchy "$tdir"/foo/bar/plop
! clean_hierarchy "$tdir"/foo/bar/plop/aa

clean_hierarchy "$tdir"/foo/bar
clean_hierarchy "$tdir"

cd "$tdir"

test "$(find . -type d | sort -V)" = '.
./bar
./bar/.hbb
./bar/aa
./yo'

test "$(find . -type f | sort -V)" = './bar/.hf1
./bar/.hf2
./bar/aa/.hf1
./bar/aa/.hf2
./bar/aa/f1
./bar/aa/f2
./bar/aa/f3
./bar/f1
./bar/f2
./bar/f3
./bar/.hbb/.hf1
./bar/.hbb/.hf2
./bar/.hbb/f1
./bar/.hbb/f2
./bar/.hbb/f3'

test "$(find . | sort -V)" = '.
./bar
./bar/.hbb
./bar/.hf1
./bar/.hf2
./bar/aa
./bar/aa/.hf1
./bar/aa/.hf2
./bar/aa/f1
./bar/aa/f2
./bar/aa/f3
./bar/f1
./bar/f2
./bar/f3
./bar/.hbb/.hf1
./bar/.hbb/.hf2
./bar/.hbb/f1
./bar/.hbb/f2
./bar/.hbb/f3
./yo'

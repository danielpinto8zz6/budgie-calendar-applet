#!/bin/sh

set -e

mkdir -p m4

intltoolize --copy --force --automake
autoreconf --force --install --symlink --warnings=all

args="\
--sysconfdir=/etc \
--localstatedir=/var \
--prefix=/usr \
--enable-silent-rules"

./configure CFLAGS="-g -O1 $CFLAGS" $args "$@"
make clean

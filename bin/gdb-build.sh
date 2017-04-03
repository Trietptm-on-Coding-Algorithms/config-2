#!/bin/bash
set -ex

VERSION=7.12

sudo apt-get build-dep gdb

dir=$(mktemp -d)
pushd $dir

wget https://ftp.gnu.org/gnu/gdb/gdb-$VERSION.tar.xz
tar xf gdb-$VERSION.tar.xz

mkdir usr

./configure \
    --prefix="$PWD/usr" \
    --enable-targets=all \
    --without-python \
    --with-tui

make -j$(nproc)

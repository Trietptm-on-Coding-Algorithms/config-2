#!/bin/sh
set -ex

VERSION=7.11

sudo apt-get build-dep gdb

dir=$(mktemp -d)
pushd $dir

wget https://ftp.gnu.org/gnu/gdb/gdb-$VERSION.tar.xz
tar xf gdb-$VERSION.tar.xz

cd gdb-$VERSION

export LDFLAGS=-static

./configure --disable-inprocess-agent \
            --disable-host-shared \
            --disable-multilib \
            --enable-static

# One can also specify the target architecture for gdbserver.
# --host=aarch64-linux-gnu

make -j$(nproc)
cp ./gdb/gdbserver/gdbserver ..

cd ..
rm -rf gdb-$VERSION*

upx -9 gdbserver

popd

echo gdbserver built at $dir/gdbserver

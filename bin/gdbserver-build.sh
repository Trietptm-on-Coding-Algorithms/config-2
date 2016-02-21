#!/bin/sh
set -ex

sudo apt-get build-dep gdb

dir=$(mktemp -d)
pushd $dir

wget https://ftp.gnu.org/gnu/gdb/gdb-7.10.tar.xz
tar xf gdb-7.10.tar.xz

cd gdb-7.10

export LDFLAGS=-static
./configure --disable-inprocess-agent --disable-host-shared --disable-multilib --enable-static
make -j$(nproc)
cp ./gdb/gdbserver/gdbserver ..

cd ..
rm -rf gdb-7.10*

upx -9 gdbserver

popd

echo gdbserver built at $dir/gdbserver

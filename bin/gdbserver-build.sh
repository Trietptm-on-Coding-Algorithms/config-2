#!/bin/sh
set -ex
export LDFLAGS=-static
./configure --disable-inprocess-agent --disable-host-shared --disable-multilib --enable-static
make -j$(nproc)
cp ./gdb/gdbserver/gdbserver .
upx -9 gdbserver

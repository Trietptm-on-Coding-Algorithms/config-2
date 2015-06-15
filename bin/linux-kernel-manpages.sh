#!/bin/sh

apt-get build-dep linux-image-$(uname -r)
apt-get source    linux-image-$(uname -r)
pushd linux-*/
make mandocs -j
sudo make installmandocs
popd
rm -rf linux*

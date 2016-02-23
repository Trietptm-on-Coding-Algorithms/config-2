#!/bin/sh

pushd $(mktemp -d)

apt-get build-dep linux-image-$(uname -r)
apt-get source    linux-image-$(uname -r)
make mandocs -j
sudo make installmandocs -j

rm -rf "$PWD"

popd

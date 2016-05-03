#!/bin/sh
set -e

unset CC
unset CXX

cd ~

# LLVM
if [ ! -d ~/llvm ]; then
mkdir llvm
pushd llvm
wget http://llvm.org/releases/3.8.0/clang+llvm-3.8.0-x86_64-linux-gnu-ubuntu-14.04.tar.xz
# wget http://llvm.org/releases/3.6.2/clang+llvm-3.6.2-x86_64-linux-gnu-ubuntu-14.04.tar.xz
# wget http://llvm.org/releases/3.6.0/clang+llvm-3.6.0-x86_64-linux-gnu-ubuntu-14.04.tar.xz
tar -xf clang*.tar.xz --strip=1
popd
fi

export PATH=~/llvm/bin:$PATH

# AFL
if [ ! -d ~/afl ]; then
mkdir ~/afl
pushd ~/afl
wget http://lcamtuf.coredump.cx/afl/releases/afl-latest.tgz
tar -xf afl-latest.tgz --strip=1
make -j
cd llvm_mode
make -j
popd
fi

echo '$ export CC=afl-clang-fast'
echo '$ export CXX=afl-clang-fast++'
echo '$ export PATH="$HOME/llvm/bin:$PATH"'
echo '$ export PATH="$HOME/afl:$PATH"'
echo '$ export AFL_PATH="$HOME/afl"'
echo '$ export AFL_USE_ASAN=1'
echo '$ export AFL_HARDEN=1'
echo '$ echo core | sudo tee /proc/sys/kernel/core_pattern'
echo '$ echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'

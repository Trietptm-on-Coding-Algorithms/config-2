#!/bin/sh
set -e

unset CC
unset CXX

cd ~

# LLVM
if [ ! -d ~/llvm ]; then
  mkdir llvm
  pushd llvm
  wget http://releases.llvm.org/4.0.0/clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-14.04.tar.xz
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

echo '$ export PATH="$HOME/llvm/bin:$PATH"'
echo '$ export AFL_PATH="$HOME/afl"'
echo '$ export AFL_USE_ASAN=1'
echo '$ export CC=$AFL_PATH/afl-gcc'
echo '$ export CXX=$AFL_PATH/afl-g++'
echo '$ export CFLAGS="-fsanitize=address -m32'
echo '$ export LDFLAGS=-fsanitize=address'
echo '$ echo core | sudo tee /proc/sys/kernel/core_pattern'
echo '$ echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'

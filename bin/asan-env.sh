#!/bin/sh

# Flags for building
export CC=clang
export CXX=clang++
export AR=llvm-ar
export CFLAGS="$CFLAGS -g -fsanitize=address -fno-omit-frame-pointer"
export CXXFLAGS="$CXXFLAGS -g -fsanitize=address -fno-omit-frame-pointer"
export LDFLAGS="$LDFLAGS -fsanitize=address -fno-omit-frame-pointer"
export DEB_CFLAGS_APPEND="$CFLAGS"
export DEB_CXXFLAGS_APPEND="$CXXFLAGS"
export DEB_LDFLAGS_APPEND="$LDFLAGS"

# ASAN needs to know where llvm-symbolizer is
for symbolizer in llvm-symbolizer{,-3.{6,5,4}};
do
	> /dev/null 2>&1 which $symbolizer && export ASAN_SYMBOLIZER_PATH=$(which $symbolizer)
done

export ASAN_OPTIONS=symbolize=1:log_path=/tmp/asan-crash-

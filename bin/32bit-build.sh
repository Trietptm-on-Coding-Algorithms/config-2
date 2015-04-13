
[ -z "$CC" ] || export CC="$CC -m32"
[ -z "$CXX" ] || export CC="$CXX -m32"
export CFLAGS=-m32
export CXXFLAGS=-m32
export LDFLAGS=-m32

echo May also want to:
echo ./configure --build=i686-pc-linux-gnu
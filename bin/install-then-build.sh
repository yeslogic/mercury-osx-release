#!/usr/bin/env bash

set -e
set -o pipefail
set -u

MACOSX_DEPLOYMENT_TARGET=10.13

BASE_URL=https://github.com/Mercury-Language/mercury-srcdist/archive
MERCURY_ROTD=${MERCURY_ROTD:-2022-02-26}

CWD=$( cd "$( dirname "$0" )/.." && pwd )
DLD_DIR=$CWD/downloads
SRC_DIR=$DLD_DIR/mercury-srcdist-rotd-$MERCURY_ROTD
OUT_DIR=$CWD/output

PARALLEL="-j$( sysctl -n hw.ncpu )"

if [ ! -f "$DLD_DIR/rotd-$MERCURY_ROTD.tar.gz" ] ; then
    ( mkdir -p "$DLD_DIR" &&
      cd "$DLD_DIR" &&
      curl -LO "$BASE_URL/rotd-$MERCURY_ROTD.tar.gz" )
fi

# Build x86_64 Mercury.
rm -rf "$SRC_DIR"
tar xvf "$DLD_DIR/rotd-$MERCURY_ROTD.tar.gz" -C "$DLD_DIR"

X86_64_TRIPLE=x86_64-apple-darwin

pushd "$SRC_DIR"

./configure \
    --with-macosx-deployment-target="$MACOSX_DEPLOYMENT_TARGET" \
    --enable-libgrades=hlc.gc,hlc.par.gc \
    --prefix="/tmp/mercury-rotd-$MERCURY_ROTD-$X86_64_TRIPLE"

make PARALLEL="$PARALLEL"
make install PARALLEL="$PARALLEL"

popd

X86_64_TARBALL=mercury-rotd-$MERCURY_ROTD-$X86_64_TRIPLE.tar.gz

if [ ! -f "$OUT_DIR/$X86_64_TARBALL" ] ; then
    ( mkdir -p "$OUT_DIR" && tar zcf "$OUT_DIR/$X86_64_TARBALL" \
      -C /tmp "mercury-rotd-$MERCURY_ROTD-$X86_64_TRIPLE" )
fi

# Build aarch64 Mercury.
rm -rf "$SRC_DIR"
tar xvf "$DLD_DIR/rotd-$MERCURY_ROTD.tar.gz" -C "$DLD_DIR"

export PATH="/tmp/mercury-rotd-$MERCURY_ROTD-$X86_64_TRIPLE/bin:$PATH"
export CC="clang -target aarch64-apple-darwin"
AARCH64_TRIPLE=aarch64-apple-darwin

pushd "$SRC_DIR"

# Manually overwrite the older version of configure_cross for now.
# Remove once we are using ROTD 2022-08-18 or newer.
cp "$CWD/bin/configure-cross-5f1dfc806f87" tools/configure_cross
./tools/configure_cross \
    --host=aarch64-apple-darwin \
    --with-macosx-deployment-target="$MACOSX_DEPLOYMENT_TARGET" \
    --enable-libgrades=hlc.par.gc \
    --prefix="/tmp/mercury-rotd-$MERCURY_ROTD-$AARCH64_TRIPLE"

mmake depend
mmake MMAKEFLAGS="$PARALLEL"
mmake install MMAKEFLAGS="$PARALLEL"

./tools/copy_mercury_binaries \
    "/tmp/mercury-rotd-$MERCURY_ROTD-$X86_64_TRIPLE" \
    "/tmp/mercury-rotd-$MERCURY_ROTD-$AARCH64_TRIPLE"

popd

AARCH64_TARBALL=mercury-rotd-$MERCURY_ROTD-$AARCH64_TRIPLE.tar.gz

if [ ! -f "$OUT_DIR/$AARCH64_TARBALL" ] ; then
    ( mkdir -p "$OUT_DIR" && tar zcf "$OUT_DIR/$AARCH64_TARBALL" \
      -C /tmp "mercury-rotd-$MERCURY_ROTD-$AARCH64_TRIPLE" )
fi

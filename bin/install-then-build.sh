#!/bin/bash

set -e
set -o pipefail
set -u

CWD=$(pwd | perl -pe 's{/bin$}{}')

if [ "$UID" != "0" ]; then
  echo "Error: this needs to be run as root"
  false
fi

# which Mercury ROTD?

MERCURY_ROTD=${MERCURY_ROTD:-2020-04-15}
TARBALL=rotd-$MERCURY_ROTD

mkdir -p repos

if [ ! -f "repos/$TARBALL.tar.gz" ]; then
  wget -O "repos/$TARBALL.tar.gz" https://github.com/Mercury-Language/mercury-srcdist/archive/$TARBALL.tar.gz
fi

SRCDIR=repos/mercury-srcdist-$TARBALL

if [ ! -d "$SRCDIR" ]; then
  tar xzf "repos/$TARBALL.tar.gz" -C repos
fi

# build Mercury

cd "$SRCDIR"
./configure

CPUS=$(sysctl -n hw.ncpu)
perl -pe "s/# PARALLEL=-j2/PARALLEL=-j$CPUS/" -i Makefile

make
make install

BINDIR=/usr/local/mercury-$TARBALL
grep -s "$BINDIR" ~/.bashrc || echo "PATH=$BINDIR/bin:\$PATH" >> ~/.bashrc

mkdir -p "$CWD/output"

if [ ! -f "$CWD/output/mercury-$TARBALL-osx.tar.gz" ]; then
  tar zcf $CWD/output/mercury-$TARBALL-osx.tar.gz -C /usr/local mercury-$TARBALL
fi

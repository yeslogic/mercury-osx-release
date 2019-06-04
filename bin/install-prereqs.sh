#!/bin/bash

set -e
set -o pipefail
set -u

if [ "$UID" == "0" ]; then
  echo "Error: do not run this as root. Please use your user account"
  false
fi

read -r -d '' PACKAGES << EOF || true
  fakeroot
  nasm
  pkg-config
  poppler
  xz
  wget
EOF

for i in $PACKAGES; do
  brew info $i | grep "Not installed" > /dev/null && brew install $i
done

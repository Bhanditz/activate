#!/bin/bash -xe

7za | head -2
xcodebuild -version
clang --version

export ACTIVATE_VERSION=head
if [ -n "$CI_BUILD_TAG" ]; then
  export ACTIVATE_VERSION=$CI_BUILD_TAG
fi
export CI_VERSION=$CI_BUILD_REF_NAME
export ACTIVATE_CFLAGS="-DACTIVATE_VERSION=\\\"$ACTIVATE_VERSION\\\""

make
file activate
./activate -V

export CI_OS="darwin"
export CI_ARCH="amd64"

7za a activate.7z activate

# set up a file hierarchy that ibrew can consume, ie:
#
# - dl.itch.ovh
#   - activate
#     - darwin-amd64
#       - LATEST
#       - v0.3.0
#         - darwin.7z
#         - darwin
#         - SHA1SUMS

BINARIES_DIR="binaries/$CI_OS-$CI_ARCH"
mkdir -p $BINARIES_DIR/$CI_VERSION
mv activate.7z $BINARIES_DIR/$CI_VERSION
mv activate $BINARIES_DIR/$CI_VERSION

(cd $BINARIES_DIR/$CI_VERSION && sha1sum * > SHA1SUMS)

if [ -n "$CI_BUILD_TAG" ]; then
  echo $CI_BUILD_TAG > $BINARIES_DIR/LATEST
fi


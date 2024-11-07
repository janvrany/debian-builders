#!/bin/bash

set -xe

if [ -d /build ]; then
  BUILD_ROOT=/build
elif [ ! -z "$HOME" ]; then
  BUILD_ROOT=$HOME
else
  BUILD_ROOT=/tmp
fi

sudo apt -y install \
  curl \
  libssl-dev \
  libx11-dev \
  libsdl2-dev

SRC_DIR=$BUILD_ROOT/omr

pushd $(dirname "$SRC_DIR")
  if [ -d "$SRC_DIR" ]; then
     git -C "$SRC_DIR" pull
  else
     git clone --depth=1 https://github.com/janvrany/pharo-vm "$SRC_DIR"
  fi
  $SRC_DIR/scripts/ci/github_build.sh

popd
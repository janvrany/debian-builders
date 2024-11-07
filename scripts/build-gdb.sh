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
  python3-dev \
  libexpat1-dev \
  libncurses-dev \
  libncurses5-dev \
  libncursesw5-dev \
  libdebuginfod-dev \
  libgmp-dev \
  libmpfr-dev \
  liblzma-dev \
  libreadline-dev \
  guile-3.0-dev

SRC_DIR=$BUILD_ROOT/binutils-gdb

pushd $(dirname "$SRC_DIR")
  if [ -d "$SRC_DIR" ]; then
     git -C "$SRC_DIR" pull
  else
     git clone --depth=1 https://github.com/janvrany/binutils-gdb-devscripts.git "$SRC_DIR"
  fi
  pushd "$SRC_DIR"
    ./test.sh
  popd
popd
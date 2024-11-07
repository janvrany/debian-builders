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
  zlib1g \
  zlib1g-dev \
  libglib2.0-dev \
  libdwarf-dev \
  libelf-dev \
  libx11-dev \
  libxext-dev \
  libxrender-dev \
  libxrandr-dev \
  libxtst-dev \
  libxt-dev \
  libasound2-dev \
  libcups2-dev \
  libfontconfig1-dev

SRC_DIR=$BUILD_ROOT/omr

pushd $(dirname "$SRC_DIR")
  if [ -d "$SRC_DIR" ]; then
     git -C omr pull
  else
     git clone --depth=1 https://github.com/eclipse/omr.git
  fi
  mkdir -p "$SRC_DIR/build"
  pushd "$SRC_DIR/build"
    sysroot=$(qemu-riscv64-static --help | grep ^QEMU_LD_PREFIX | sed -e 's#^.*= /#/#g')

    cmake .. -Wdev -C../cmake/caches/Travis.cmake \
		-DOMR_DDR=OFF \
		-DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/riscv64-linux-cross.cmake \
 		-DCMAKE_SYSROOT=$sysroot \
		"-DOMR_EXE_LAUNCHER=qemu-riscv64-static;-L;$sysroot"
  make -j$(nproc)
  make test
  popd
popd
#!/bin/bash
#
# Install GCC 8 on x86_64 builders - GCC 8 is required to build Pharo VM.
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#
: ${CONFIG_GCC8_VER:=8.5.0}

if false; then
# Skip if target architecture is not x86_64
test "amd64" == "$(chroot "$ROOT" dpkg-architecture -q DEB_TARGET_ARCH)" || exit 0

if chroot "${ROOT}" apt-cache pkgnames | grep -q gcc-8; then
    #
    # Try to install GCC 8 from repository
    #
    chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
        gcc-8 g++-8
else
    #
    # Otherwise, compile it from source
    #
    chroot "${ROOT}" apt-get install -y gcc-multilib libgmp-dev libmpfr-dev libmpc-dev git quilt
    echo "
    set -e

    ver=${CONFIG_GCC8_VER}

    apt-get install -y gcc-multilib libgmp-dev libmpfr-dev libmpc-dev
    wget -O/tmp/gcc-\$ver.tar.gz https://ftp.gnu.org/gnu/gcc/gcc-\$ver/gcc-\$ver.tar.gz
    tar -C /tmp -xf /tmp/gcc-\$ver.tar.gz

    pushd /tmp/gcc-\$ver
        ./configure --prefix=/opt/gcc-8 --disable-libsanitizer --enable-bootstrap=no
        make -j \$(nproc)
        make install
    popd

    #pushd /usr/local/bin
    #    for f in /opt/gcc-8/bin/g*; do
    #        ln -s \$f \$(basename \$f)-8
    #    done
    #popd
    " | sudo tee "$ROOT/tmp/gcc-8-build.sh"

    chroot "${ROOT}" bash -x "/tmp/gcc-8-build.sh"
fi
fi
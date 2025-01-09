#!/bin/bash
#
# Install GCC 8 on x86_64 builders - GCC 8 is required to build Pharo VM
# and Smalltalk/X (only if building 32bit version, though!)
#
set -e

source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#
: ${CONFIG_GCC8_VER:=8.5.0}
: ${CONFIG_BUILD_TMP_DIR:=$(realpath "tmp")}

if true; then
# Following is just to make sure sudo works without asking for password.
sudo true
# Skip if target architecture is not x86_64
test "amd64" == "$(/usr/bin/sudo chroot "$ROOT" dpkg-architecture -q DEB_TARGET_ARCH)" || exit 0

if sudo chroot "${ROOT}" apt-cache pkgnames | grep -q gcc-8-multilib; then
    #
    # Try to install GCC 8 from repository
    #
    sudo chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
        gcc-8-multilib g++-8
else
    #
    # Otherwise, compile it from source
    #
    mkdir -p "$$CONFIG_BUILD_TMP_DIR"
    sudo mount -o bind,rw "$CONFIG_BUILD_TMP_DIR" "$ROOT/tmp"

    echo "
    set -e

    ver=${CONFIG_GCC8_VER}

    if [ -f /tmp/gcc-\$ver-bin.tar.gz ]; then
    tar -C / -xzvf /tmp/gcc-\$ver-bin.tar.gz
    else
    apt-get install -y gcc-multilib libgmp-dev libmpfr-dev libmpc-dev
    test -f /tmp/gcc-\$ver.tar.gz || wget -O/tmp/gcc-\$ver.tar.gz https://ftp.gnu.org/gnu/gcc/gcc-\$ver/gcc-\$ver.tar.gz
    test -d /tmp/gcc-\$ver || tar -C /tmp -xf /tmp/gcc-\$ver.tar.gz

    pushd /tmp/gcc-\$ver
        ./configure --prefix=/opt/gcc-8 --disable-libsanitizer --enable-bootstrap=no
        make -j \$(nproc)
        make install
    popd
    apt-get remove libgmp-dev libmpfr-dev libmpc-dev

    pushd /usr/local/bin
        for f in /opt/gcc-8/bin/g*; do
            ln -s \$f \$(basename \$f)-8
        done
    popd

    tar -C / -czf /tmp/gcc-\$ver-bin.tar.gz opt/gcc-8 usr/local/bin/g*-8
    fi

    " | sudo tee "$ROOT/tmp/gcc-8-build.sh"

    sudo chroot "${ROOT}" bash -x "/tmp/gcc-8-build.sh"
    sudo umount "$ROOT/tmp"
    mount
fi
fi
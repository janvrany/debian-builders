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

function install_gcc() {
    local ver=$1
    local ver_maj="${ver%%.*}"

    if sudo chroot "${ROOT}" apt-cache pkgnames | grep -q "gcc-${ver_maj}-multilib"; then
        #
        # Try to install GCC 8 from repository
        #
        sudo chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
            "gcc-${ver_maj}-multilib" "g++-${ver_maj}"
    else
        #
        # Otherwise, compile it from source
        #
        mkdir -p "$CONFIG_BUILD_TMP_DIR"
        sudo mount -o bind,rw "$CONFIG_BUILD_TMP_DIR" "$ROOT/tmp"
        sudo cp $(dirname $(realpath $0))/../scripts/install-gcc.sh "${ROOT}/tmp"


        sudo chroot "${ROOT}" bash -x "/tmp/install-gcc.sh" -l "${ver}"
        sudo umount "$ROOT/tmp"
        mount
    fi
}

install_gcc 8.5.0
#install_gcc 9.5.0

fi
#!/bin/bash
#
# Install custom QEMU(s)
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#
: ${CONFIG_QEMU_VERSIONS:=}

#
# Install QEMU build prerequisites
#
chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
    build-essential git cmake ninja-build pkg-config libglib2.0-dev

function in_chroot_install_qemu() {
    local qemu_ver=$1
    local qemu_src="/usr/src/qemu"
    local qemu_bld="$qemu_src/build"
    local qemu_targets=riscv64-linux-user,ppc64le-linux-user,aarch64-linux-user

    if [ ! -d "$ROOT/$qemu_src" ]; then
        sudo git clone https://gitlab.com/qemu-project/qemu.git "$ROOT/$qemu_src"
        #git -C "$ROOT/$qemu_src" submodule init
        #git -C "$ROOT/$qemu_src" submodule update --recursive
    fi

    sudo git -C "$ROOT/$qemu_src" checkout "$qemu_ver"

    sudo rm -rf "$ROOT/$qemu_bld"
    sudo mkdir  "$ROOT/$qemu_bld"

    chroot "${ROOT}" ls -al $qemu_src

    chroot "${ROOT}" bash -c "(cd $qemu_bld && $qemu_src/configure --prefix=/opt/qemu-$qemu_ver --target-list=$qemu_targets --static)"
    chroot "${ROOT}" bash -c "(cd $qemu_bld && make -j$(nproc) && make install)"
}

if [ ! -z "$CONFIG_QEMU_VERSIONS" ]; then
    for qemu_ver in $CONFIG_QEMU_VERSIONS; do
        in_chroot_install_qemu $qemu_ver
    done
fi


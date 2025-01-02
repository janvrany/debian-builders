#!/bin/bash
#
# Install build tools and dev libraries
#
set -e

source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#
: ${CONFIG_BUILD_ARCHS:=$(chroot "$ROOT" dpkg-architecture -q DEB_TARGET_ARCH)}

#
# Packages required to build (selected) projects
#
PACKAGES_GDB="  python3-dev,
                libexpat1-dev,
                libncurses-dev,
                libncurses5-dev,
                libncursesw5-dev,
                libdebuginfod-dev,
                libgmp-dev,
                libmpfr-dev,
                liblzma-dev,
                libreadline-dev,
                guile-3.0-dev,
            "

#
# See https://jan.vrany.io/stx/wiki/Documentation/BuildingStXWithRakefiles#Debianonx86_64andotherderivativessuchasUbuntuorMint
#
PACKAGES_STX="  pkg-config,
                libc6-dev,
                libx11-dev,
                libxext-dev,
                libxinerama-dev,
                unixodbc-dev,
                libgl1-mesa-dev,
                libfl-dev,
                libxft-dev,
                libbz2-dev,
                zlib1g,
                zlib1g-dev
            "

PACKAGES_OMR="  zlib1g,
                zlib1g-dev,
                libglib2.0-dev,
                libdwarf-dev,
                libelf-dev,
                libx11-dev,
                libxext-dev,
                libxrender-dev,
                libxrandr-dev,
                libxtst-dev,
                libxt-dev,
                libasound2-dev,
                libcups2-dev,
                libfontconfig1-dev"

PACKAGES="      libc6,
                ${PACKAGES_GDB},
                ${PACKAGES_STX},
                ${PACKAGES_OMR}
                "
#
# Install common built tools. Note, that mercurial is installed separately
#
chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
    build-essential git cmake ninja-build pkg-config libglib2.0-dev gdb ccache curl \
    bison flex dejagnu texinfo rake cvs ant

#
# Create sysroot for each architecture
#
for arch in $CONFIG_BUILD_ARCHS; do
    if [[ "$arch" == "$(chroot "$ROOT" dpkg-architecture -q DEB_TARGET_ARCH)" ]]; then
        #
        # Setup toolchain for native builds
        #
        chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
            $(echo $PACKAGES | sed -s "s/,/ /g")
    else
        #
        # Setup toolchain for cross-compiling
        #
        if chroot "${ROOT}" apt-cache pkgnames | grep -q crossbuild-essential-$arch; then
            chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
                crossbuild-essential-$arch
        else
            chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
                gcc-$arch-linux-gnu g++-$arch-linux-gnu
        fi
        chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
            qemu-user-static

        if [[ "$arch" == "riscv64" ]]; then
            sudo wget "-O${ROOT}/usr/local/include/riscv.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv.h;hb=2f973f134d7752cbc662ec65da8ad8bbe4c6fb8f'
            sudo wget "-O${ROOT}/usr/local/include/riscv-opc.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv-opc.h;hb=2f973f134d7752cbc662ec65da8ad8bbe4c6fb8f'
        fi

        #
        # Create sysroot
        #
        # Here we install sysroot into directory used by qemu by default
        # (so we do not have pass down -L parameter or set QEMU_LD_PREFIX).
        # However, that default differs:
        #
        #  * /usr/gnemul/qemu-$arch (on Debian Trixie)
        #  * /etc/qemu-binfmt/$arch (on Debian Bookworm)
        #
        # So, we put stuff to /usr/gnemul and create symlink for compatibility.
        # Sigh.
        sysroot="/usr/gnemul/qemu-$arch"
        sysroot_alt="/etc/qemu-binfmt/$arch"
        mkdir -p "${ROOT}/$sysroot"
        bash "$(dirname $(realpath ${BASH_SOURCE[0]}))/../scripts/build-sysroot.sh" \
            -a "$arch" \
            -d "${ROOT}/$sysroot" \
            -p "$PACKAGES"
        if [[ "$arch" == "riscv64" ]]; then
            sudo wget "-O${ROOT}/$sysroot/usr/include/riscv.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv.h;hb=2f973f134d7752cbc662ec65da8ad8bbe4c6fb8f'
            sudo wget "-O${ROOT}/$sysroot/usr/include/riscv-opc.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv-opc.h;hb=2f973f134d7752cbc662ec65da8ad8bbe4c6fb8f'
        fi

        mkdir -p "${ROOT}/$(dirname $sysroot_alt)"
        (cd "${ROOT}/$(dirname $sysroot_alt)" && ln -s "$sysroot" $(basename $sysroot_alt))
    fi
done

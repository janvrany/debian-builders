#!/bin/bash

set -e

usage() { echo "Usage: $0 -a ARCH [-r SUITE] [-d DIRECTORY] [-p PACKAGES]" 1>&2; exit 1; }

while getopts ":a:r:d:p:" o; do
    case "${o}" in
        a)
            ARCH=${OPTARG}
            ;;
        r)
            SUITE=${OPTARG}
            ;;
        d)
            DIRECTORY=${OPTARG}
            ;;
        p)
            PACKAGES=${OPTARG}
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${ARCH}" ]; then
    usage
fi

if [ -z "${SUITE}" ]; then
    if [ "${ARCH}" == "riscv64" ]; then
        SUITE=sid
    else
        SUITE=bookworm
    fi
fi

if [ -z "${DIRECTORY}" ]; then
    DIRECTORY="qemu-${ARCH}"
fi

echo "architecture  = ${ARCH}"
echo "suite/release = ${SUITE}"
echo "sysroot       = ${DIRECTORY} [ $(realpath $DIRECTORY) ]"

mkdir -p "${DIRECTORY}"

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
PACKAGES_STX="  rake,
                pkg-config,
                libc6-dev,
                libx11-dev,
                libxext-dev,
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

if [ -z "$PACKAGES" ]; then
    PACKAGES="  libc6,
                ${PACKAGES_GDB},
                ${PACKAGES_STX},
                ${PACKAGES_OMR}
                "
fi

# Bootstrap!
mmdebstrap \
    --mode=fakeroot \
    --variant=extract \
    --architectures=$ARCH \
    --include="$PACKAGES" \
    "$SUITE" "$DIRECTORY" \
    "deb http://deb.debian.org/debian $SUITE main contrib"

# Link dynamic linker to /lib (needed for execution using QEMU)
(mkdir -p "${DIRECTORY}/lib" \
    && cd "${DIRECTORY}/lib" \
    && ln -s $(ls ../usr/lib/ld-linux*.so*) .)

# Link libraries to /lib (needed for OpenJ9 compilation)
(mkdir -p "${DIRECTORY}/lib" \
    && cd "${DIRECTORY}/lib" \
    && ln -s "../usr/lib/$ARCH-linux-gnu" .)

# Download and install riscv.h and riscv-opc.h - these are really needed only for
# RISC-V development, but won't hurt having them.
mkdir -p "${DIRECTORY}/usr/include"
wget "-O${DIRECTORY}/usr/include/riscv.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv.h;hb=2f973f134d7752cbc662ec65da8ad8bbe4c6fb8f'
wget "-O${DIRECTORY}/usr/include/riscv-opc.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv-opc.h;hb=2f973f134d7752cbc662ec65da8ad8bbe4c6fb8f'

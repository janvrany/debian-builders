#!/bin/bash
function usage() { echo "
Install GCC to /opt

Usage: $0 [-l] <VER>

  <VER>  GCC version to install, in form of X.Y.Z
  -l     if specified, also install links to /usr/local/bin

"
}


set -e

lnk=no

while getopts ":l" o; do
    case "${o}" in
        l)
            lnk=yes
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -z "$1" ]]; then
    echo "ERROR: No GCC version given"
    echo "Usage: $0 [-l] <VER>"
    exit 1
elif [[ ! "$1" =~ [0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: Invalid version: $1"
    echo "Usage: $0 [-l] <VER>"
    exit 1
else
    ver=$1
    ver_maj="${ver%%.*}"
fi


echo -n "Installing GCC $ver to /opt/gcc-$ver_maj"
if [ "$lnk" == "yes" ]; then
    echo " and to /usr/local/bin"
else
    echo
fi

if [ -f /tmp/gcc-$ver-bin.tar.gz ]; then
    echo "Found precompiled binaries in /tmp/gcc-$ver-bin.tar.gz"
    tar -C / -xzvf /tmp/gcc-$ver-bin.tar.gz
else
    sudo apt-get install -y \
        build-essential \
        gcc-multilib \
        libgmp-dev libmpfr-dev libmpc-dev

    # The code below does not work, for some reason GCC 8.5.9 fails
    # to compile without gcc-multilib :-(
    #
    #sudo apt-get install -y \
    #    build-essential \
    #    libgmp-dev libmpfr-dev libmpc-dev
    #sudo apt-get install -y \
    #    libx32gcc-$(gcc -dumpversion)-dev \
    #    lib32gcc-$(gcc -dumpversion)-dev \
    #    libc6-dev-x32 \
    #    libc6-dev-i386
    test -f /tmp/gcc-$ver.tar.gz || wget -O/tmp/gcc-$ver.tar.gz https://ftp.gnu.org/gnu/gcc/gcc-$ver/gcc-$ver.tar.gz
    test -d /tmp/gcc-$ver || tar -C /tmp -xf /tmp/gcc-$ver.tar.gz

    pushd /tmp/gcc-$ver
        ./configure --prefix=/opt/gcc-$ver_maj \
            --disable-libsanitizer \
            --enable-bootstrap=no \
            --enable-languages=c,c++,lto

        make -j $(nproc)
        make install
        make distclean
    popd

    tar -C / -czf "/tmp/gcc-$ver-bin.tar.gz" "opt/gcc-$ver_maj"
    echo "Saved precompiled binaries in /tmp/gcc-$ver-bin.tar.gz"
fi

if [ "$lnk" == "yes" ]; then
    pushd /usr/local/bin
         for f in /opt/gcc-$ver_maj/bin/g*; do
             ln -s $f "$(basename $f)-$ver_maj"
         done
    popd
fi

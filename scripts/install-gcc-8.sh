set -e

rev=de1d844aa05b66296f49a4ec66b75c605756df09
ver=8.4.0
dir=/tmp/gcc-8

#sudo apt-get install -y gcc-multilib libgmp-dev libmpfr-dev libmpc-dev git quilt

test -d $dir/.git || git clone https://salsa.debian.org/toolchain-team/gcc.git -b gcc-8-debian $dir
git -C $dir checkout $rev
test -f $dir/gcc-$ver.tar.gz || wget -O$dir/gcc-$ver.tar.gz https://ftp.gnu.org/gnu/gcc/gcc-$ver/gcc-$ver.tar.gz

pushd $dir
	rm -rf ./bld
	rm -rf ./src
	rm -rf ./stamps

	make -f debian/rules patch || true

	mkdir bld
	pushd bld
		../src/configure --prefix=/opt/gcc-8 --disable-libsanitizer --enable-bootstrap=no --enable-languages=c,c++
    	make -j $(nproc)
    	make install
    popd
popd

exit 1

pushd /usr/local/bin
    for f in /opt/gcc-8/bin/g*; do
		ln -s $f $(basename $f)-8
	done
popd
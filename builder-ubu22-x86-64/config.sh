CONFIG_HOSTNAME=$(basename $(dirname $(realpath ${BASH_SOURCE[0]})))
CONFIG_DEBIAN_RELEASE=jammy
CONFIG_BUILD_ARCHS="amd64 riscv64"
CONFIG_VM_MEM=8G

#CONFIG_QEMU_VERSIONS="v7.2.0 v7.0.0 v6.0.0 v5.0.0"
#CONFIG_RUN_IN_CONTAINER_BIND_USER=yes

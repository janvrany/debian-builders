#!/bin/bash
#
# Install few extra packages
#
set -e

source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#
#: ${CONFIG_VAR:=default}

#
# Install NFS support and some monitoring tools
#
chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
	nfs-common htop btop iotop
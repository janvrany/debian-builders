#!/bin/bash
#
# Install Mercurial and evolve/topic extension
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#
: ${CONFIG_MERCURIAL_INSTALL_DIR:=/opt/mercurial}

# build-essential is needed to build Mercurial's native code
chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
	python3 python3-dev python3-pip build-essential virtualenv

#
# Create virtualenv for Mercurial to make it self-contained
#
chroot "${ROOT}" /usr/bin/virtualenv -p python3 "${CONFIG_MERCURIAL_INSTALL_DIR}"

chroot "${ROOT}" "${CONFIG_MERCURIAL_INSTALL_DIR}/bin/pip" install \
	mercurial hg-evolve

(cd "${ROOT}/usr/local/bin" && ln -s "../../../${CONFIG_MERCURIAL_INSTALL_DIR}/bin/hg" .)
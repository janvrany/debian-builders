#!/bin/bash
#
# Add user (same as user who run the build) and
#
# * allow it to run apt without password
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#
# None

#
# Setup user
#
if [ "$USER" != "root" ]; then
        #
        # Allow user to install packages
        #
        echo "
$USER   ALL=(root) NOPASSWD: /usr/bin/apt install *, /usr/bin/apt-get install *,/usr/bin/apt -y install *, /usr/bin/apt-get -y install *, /usr/bin/apt update, /usr/bin/apt-get update, /usr/bin/dpkg --add-architecture *
" | sudo tee -a "${ROOT}/etc/sudoers.d/$USER"
fi
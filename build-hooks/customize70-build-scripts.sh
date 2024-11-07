#!/bin/bash
#
# Copy various build scripts to $USER's home directory
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#

for script in scripts/build-*.sh; do
    cp $(dirname $(realpath $0))/../$script "${ROOT}/${HOME}"
done

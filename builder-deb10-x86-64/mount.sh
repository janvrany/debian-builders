#!/bin/bash
#
# Bootstrap the debian
#
source "$(dirname $0)/functions.sh"
config "$(dirname $0)/config.sh"
config "$(dirname $0)/config-local.sh"

#
# Config variables
#
#: ${CONFIG_XYZ:=default}

set +x

if [ -z "$1" ]; then
    echo "usage: $(basename $0) <ROOT>"
    exit 1
fi

ensure_ROOT "$1"

echo ""
echo "Image is mounted in $ROOT"
echo ""

_PS1="$PS1"
PS1="($1) ${_PS1}" $SHELL --norc
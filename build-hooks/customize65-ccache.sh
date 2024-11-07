#!/bin/bash
#
# Configure shared cache directory for ccache
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error"Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#
: ${CONFIG_CCACHE_UID:=501}
: ${CONFIG_CCACHE_GID:=501}
: ${CONFIG_CCACHE_DIR:=/var/cache/ccache}
: ${CONFIG_CCACHE_DIR_MAX_SIZE:=5.0G}


echo "Creating user ccache..."
sudo chroot "${ROOT}" groupadd --gid "$CONFIG_CCACHE_UID" --system ccache
sudo chroot "${ROOT}" useradd  --uid "$CONFIG_CCACHE_UID" --gid "$CONFIG_CCACHE_GID" --system --home-dir $CONFIG_CCACHE_DIR ccache

sudo mkdir          "${ROOT}/$CONFIG_CCACHE_DIR"
sudo chroot "${ROOT}" chown ccache:ccache \
                            "$CONFIG_CCACHE_DIR"
sudo chmod o+w      "${ROOT}/$CONFIG_CCACHE_DIR"
sudo chmod g+s      "${ROOT}/$CONFIG_CCACHE_DIR"

# Configure
echo "
cache_dir = $CONFIG_CCACHE_DIR
max_size = $CONFIG_CCACHE_DIR_MAX_SIZE
umask = 000
" | sudo tee "$ROOT/etc/ccache.conf"

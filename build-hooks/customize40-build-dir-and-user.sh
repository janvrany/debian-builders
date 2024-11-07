#!/bin/bash
#
# Create /build directory and user builder (for automated builds)
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#
: ${CONFIG_BUILD_DIR:=/build}
: ${CONFIG_BUILD_USER:=builder}
: ${CONFIG_BUILD_USER_UID:=502}
: ${CONFIG_BUILD_USER_GID:=502}

sudo mkdir       "${ROOT}/$CONFIG_BUILD_DIR"
sudo chmod ugo+w "${ROOT}/$CONFIG_BUILD_DIR"
sudo chmod   o+s "${ROOT}/$CONFIG_BUILD_DIR"

echo "Creating user $CONFIG_BUILD_USER..."
sudo chroot "${ROOT}" groupadd --gid "$CONFIG_BUILD_USER_GID" --system $CONFIG_BUILD_USER
sudo chroot "${ROOT}" useradd  --gid "$CONFIG_BUILD_USER_GID" --uid "$CONFIG_BUILD_USER_UID" -s /bin/bash --system --home-dir "$CONFIG_BUILD_DIR" "$CONFIG_BUILD_USER"

sudo chroot "${ROOT}" chown $CONFIG_BUILD_USER:$CONFIG_BUILD_USER "$CONFIG_BUILD_DIR"

echo "
$CONFIG_BUILD_USER     ALL=(root) NOPASSWD: /usr/bin/apt install *, /usr/bin/apt-get install *,/usr/bin/apt -y install *, /usr/bin/apt-get -y install *
" | sudo tee "${ROOT}/etc/sudoers.d/$CONFIG_BUILD_USER"

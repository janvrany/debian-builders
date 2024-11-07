#!/bin/bash
#
# Local customizations - do not commit this file!
#
set -e

source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#

#
# Configure DHCP client ID
#
echo "

[DHCPv4]
#
# Use MAC address to construct DHCP client ID (rather than IAID+DUID used
# by systemd-networkd by default).
#
# This makes the DHCP server configuration for static leases much simpler,
# since it's easier to configure and compatible with what kernel IP DHCP
# autoconfiguration uses (such as when mounting root over NFS)
ClientIdentifier=mac

" | sudo tee -a "$ROOT/etc/systemd/network/99-$CONFIG_DEFAULT_NET_IFACE.network"

#
# Install support for NFS client
#

sudo chroot "${ROOT}" /usr/bin/apt-get -y install \
    nfs-common

#
# Define mounts
#

function make_mount() {
    local MOUNTPOINT=$1
    local FS=$2
    local FS_TYPE=$3
    local FS_OPTS=$4

    local MOUNTUNIT=$(echo "$MOUNTPOINT" | sed -e 's#^/##g' -e 's#/#-#g')
    local AFTER=
    local BEFORE=

    case "$FS_TYPE" in
        nfs*)
            AFTER="After=network.target"
            BEFORE="Before=remote-fs.target"
            ;;
        *)
            AFTER="After="
            BEFORE="Before=local-fs.target"
            ;;
    esac

    echo "
[Unit]
Description=Mount $MOUNTPOINT
$AFTER
$BEFORE

[Mount]
Where=$MOUNTPOINT
What=$FS
Type=$FS_TYPE
Options=$FS_OPTS

[Install]
WantedBy=multi-user.target
" | sudo tee "$ROOT/etc/systemd/system/$MOUNTUNIT.mount"

    sudo mkdir "$ROOT/etc/systemd/system/$MOUNTUNIT.mount.d"
    echo "
#
# Overrides for $MOUNTPOINT mount. Once edited, test it with
#
#     systemctl start home.mount
#
# and enable it with
#
#     systemctl enable home.mount
#
[Unit]
# $AFTER
# $BEFORE

[Mount]
# Where=$MOUNTPOINT
# What=$FS
# Type=$FS_TYPE
# Options=$FS_OPTS

" | sudo tee "$ROOT/etc/systemd/system/$MOUNTUNIT.mount.d/override.conf"

    echo "
#
# $MOUNTPOINT is mounted using '$MOUNTUNIT.mount' unit
#
# To modify, disable or enable the /tmp mount, use
#
#     systemctl edit $MOUNTUNIT.mount
#     systemctl disable $MOUNTUNIT.mount
#     systemctl enable $MOUNTUNIT.mount
#
" | sudo tee -a "$ROOT/etc/fstab"

}


make_mount "/tmp"               "tmpfs"                         "tmpfs"         ""
make_mount "/home"              "192.168.88.254:/tank/homes"    "nfs4"          "rw,async,noatime,nodiratime,vers=4.2,ac"
make_mount "/var/cache/ccache"  "PARTLABEL=ccache"                "ext4"          ""
make_mount "/var/lib/jenkins/workspace" \
                                "192.168.88.254:/temp/workspaces/%l" "nfs4"     "rw,async,noatime,nodiratime,vers=4.2,ac"

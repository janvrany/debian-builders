#!/bin/bash
set -e
#
# Add support to act as a Jenking build node
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#
: ${CONFIG_JENKINS_UID:=500}
: ${CONFIG_JENKINS_GID:=500}
: ${CONFIG_JENKINS_PUBKEY:=path-to-jenkins-master-ssh-pubkey}
: ${CONFIG_JENKINS_WORKSPACE_NFS:=}

echo "Creating user jenkins..."
sudo chroot "${ROOT}" groupadd --gid "$CONFIG_JENKINS_UID" --system jenkins
sudo chroot "${ROOT}" useradd  --uid "$CONFIG_JENKINS_UID" --gid "$CONFIG_JENKINS_GID" --system --create-home --home-dir /var/lib/jenkins --shell /usr/bin/bash /jenkins
echo "AllowUsers jenkins" | sudo tee "$ROOT/etc/ssh/sshd_config.d/jenkins.conf"

#
# Allow user `jenkins` to install packages
#
echo "
jenkins     ALL=(root) NOPASSWD: /usr/bin/apt install *, /usr/bin/apt-get install *,/usr/bin/apt -y install *, /usr/bin/apt-get -y install *, /usr/bin/apt update, /usr/bin/apt-get update, /usr/bin/dpkg --add-architecture *
" | sudo tee "${ROOT}/etc/sudoers.d/jenkins"


#
# Create ~jenkins/.ssh and default config
#
sudo mkdir -p "${ROOT}/var/lib/jenkins/.ssh"
echo "
Host *
  #
  # Turn off host key checking. This avoids ssh client refusing to connect
  # because of not-yet-known host keys - this happens first time a CI job is
  # checking out stuff or similar and this causing job to fail.
  # Not great, but we do now want such failure nor we want to manually connect
  # to build node and accept the key each time we rebuild the builder image.
  #
  StrictHostKeyChecking off
" | sudo tee "${ROOT}/var/lib/jenkins/.ssh/config"
if [ -f "$CONFIG_JENKINS_PUBKEY" ]; then
	echo "Installing public key..."
	sudo cp "$CONFIG_JENKINS_PUBKEY" "${ROOT}/var/lib/jenkins/.ssh/authorized_keys"
fi
sudo chown -R "$CONFIG_JENKINS_UID:$CONFIG_JENKINS_GID" "${ROOT}/var/lib/jenkins/.ssh"
sudo chmod -R go-rwx                                    "${ROOT}/var/lib/jenkins/.ssh"
sudo chmod -R u=rw                                      "${ROOT}/var/lib/jenkins/.ssh"
sudo chmod    u=rwx                                     "${ROOT}/var/lib/jenkins/.ssh"

echo "Installing JDK"
sudo chroot "${ROOT}" /usr/bin/apt-get -y install \
    default-jdk-headless

if [ ! -z "$CONFIG_JENKINS_WORKSPACE_NFS" ]; then
	sudo mkdir -p "${ROOT}/var/lib/jenkins/workspace"
echo "
[Unit]
Description=Mount Jenkins workspace over NFS
After=network.target
Before=remote-fs.target

[Mount]
What=$CONFIG_JENKINS_WORKSPACE_NFS
Where=/var/lib/jenkins/workspace
Type=nfs4
Options=rw,async,noatime,nodiratime,vers=4.2,ac,rsize=4096,wsize=4096

[Install]
WantedBy=multi-user.target
" | sudo tee "$ROOT/etc/systemd/system/var-lib-jenkins-workspace.mount"
chroot "${ROOT}" systemctl enable var-lib-jenkins-workspace.mount

echo "
#
# /var/var/lib/jenkins/workspace is auto-mounted using 'var-lib-jenkins-workspace.mount' unit
#
# To modify, disable or enable mount of /var/var/lib/jenkins/workspace use
#
#     systemctl edit var-lib-jenkins-workspace.mount
#     systemctl disable var-lib-jenkins-workspace.mount
#     systemctl enable var-lib-jenkins-workspace.mount
#
#

" | sudo tee -a "$ROOT/etc/fstab"
fi

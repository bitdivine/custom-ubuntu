#!/bin/bash

logfile="/var/log/ox-firstboot.log"
if touch "$logfile"; then
	exec > >(tee "$logfile") 2>&1
fi

echo Hello from XXX firstboot

set -x
set +eu
ROOTFS_DIR="${ROOTFS_DIR:-/}"

: The user needs to be able to access serial ports
PROCESSING_USER_NAME=ox
if getent passwd "$PROCESSING_USER_NAME"; then
	usermod -a -G dialout "$PROCESSING_USER_NAME"
else
	echo "ERROR: User '$PROCESSING_USER_NAME' not found."
fi

: The user must own their own files
USER_HOME="${ROOTFS_DIR}/home/ox"
if test -e "$USER_HOME"; then
	chown -R 1000:1000 "${USER_HOME}"
	chmod 755 "${USER_HOME}"
else
	echo "ERROR: '${USER_HOME}' not found"
fi

: Files with special permissions
chmod 755 "${USER_HOME}/startx"

: Install ssh keys
mkdir -p "${ROOTFS_DIR}/root/.ssh"
# It is OK for there to be only one user
# shellcheck disable=SC2043
for user in AKalyanov bitdivine oklockar op-nitsch osda StefanKleiser stoffel67; do
	{
		echo
		echo "# $user"
		curl -s https://github.com/${user}.keys
	} | tee -a "${ROOTFS_DIR}/root/.ssh/authorized_keys2" >/dev/null
done
chmod 644 "${ROOTFS_DIR}/root/.ssh/authorized_keys2"

: Disable wireless
rm -f "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/hciuart.service"
rm -f "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/wpa_supplicant.service"

: Resize the first partition
logical_volume="$(lvs --noheadings -o vg_name,lv_name | awk '{printf "/dev/%s/%s\n", $1, $2}')"
lvextend -l +100%FREE "${logical_volume}"
resize2fs "${logical_volume}"

: Reload services
udevadm control --reload-rules
systemctl daemon-reload

true

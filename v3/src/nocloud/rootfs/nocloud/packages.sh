#!/usr/bin/env bash

logfile="/var/log/ox-packages.log"
if touch "$logfile"; then
	exec > >(tee "$logfile") 2>&1
fi

echo Hello from XXX packages

function apt_install() {
	apt-get --option=Dpkg::Options::=--force-confold --option=Dpkg::options::=--force-unsafe-io --assume-yes --quiet --no-install-recommends install "${@}"
}

apt-get update

# Frame buffer viewer for the splash screen on boot
apt_install fbi

# Display
apt_install xserver-xorg-video-all xserver-xorg-input-all xserver-xorg-core xinit x11-xserver-utils xinput
# apt_install unclutter # Remove mouse pointer when not needed

# Screen-freeze detection
apt_install scrot

# App
apt_install chromium-browser
# This is done directly via cloudconfig as this script is run before the user session is ready.
# snap install chromium

# Maintenance tools
apt_install git vim socat

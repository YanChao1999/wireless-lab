# Always track upstream master/main; tested commits are recorded in
# stable/<board>.txt (see host/record-commits.sh), not pinned.
# Buildroot reads this file after the package definitions.
IW_SITE = https://git.kernel.org/pub/scm/linux/kernel/git/jberg/iw.git
IW_SITE_METHOD = git
IW_VERSION = master

WPA_SUPPLICANT_SITE = https://w1.fi/hostap.git
WPA_SUPPLICANT_SITE_METHOD = git
WPA_SUPPLICANT_VERSION = main

BLUEZ5_UTILS_SITE = https://git.kernel.org/pub/scm/bluetooth/bluez.git
BLUEZ5_UTILS_SITE_METHOD = git
BLUEZ5_UTILS_VERSION = master

WIRELESS_REGDB_SITE = https://git.kernel.org/pub/scm/linux/kernel/git/wens/wireless-regdb.git
WIRELESS_REGDB_SITE_METHOD = git
WIRELESS_REGDB_VERSION = master

LINUX_FIRMWARE_SITE = https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
LINUX_FIRMWARE_SITE_METHOD = git
LINUX_FIRMWARE_VERSION = main

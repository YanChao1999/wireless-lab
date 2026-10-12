# Build the wifi/ble userspace from upstream git (override with make VAR=ref).
# Buildroot reads this file after the package definitions.
IW_SITE = https://git.kernel.org/pub/scm/linux/kernel/git/jberg/iw.git
IW_SITE_METHOD = git
IW_VERSION = $(or $(WL_IW_REF),master)

WPA_SUPPLICANT_SITE = https://w1.fi/hostap.git
WPA_SUPPLICANT_SITE_METHOD = git
WPA_SUPPLICANT_VERSION = $(or $(WL_HOSTAP_REF),main)

BLUEZ5_UTILS_SITE = https://git.kernel.org/pub/scm/bluetooth/bluez.git
BLUEZ5_UTILS_SITE_METHOD = git
BLUEZ5_UTILS_VERSION = $(or $(WL_BLUEZ_REF),master)

WIRELESS_REGDB_SITE = https://git.kernel.org/pub/scm/linux/kernel/git/wens/wireless-regdb.git
WIRELESS_REGDB_SITE_METHOD = git
WIRELESS_REGDB_VERSION = $(or $(WL_REGDB_REF),master)

LINUX_FIRMWARE_SITE = https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
LINUX_FIRMWARE_SITE_METHOD = git
LINUX_FIRMWARE_VERSION = $(or $(WL_FW_REF),main)

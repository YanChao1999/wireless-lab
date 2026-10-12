BOARD ?= sk-am64b
BR_VERSION ?= 2024.08
# Pin refs for reproducible runs: KERNEL_REF=v7.0-rc3 WL_BLUEZ_REF=<sha> ...
KERNEL_REF ?= master
BR_DIR ?= $(CURDIR)/buildroot
OUT ?= $(CURDIR)/output/$(BOARD)
EXT := $(CURDIR)/external

base-sk-am64b := ti_am64x_sk_defconfig
base-imx8mp := freescale_imx8mpevk_defconfig
BASE := $(base-$(BOARD))

export WL_IW_REF WL_HOSTAP_REF WL_BLUEZ_REF WL_REGDB_REF WL_FW_REF

.PHONY: build flash clean check

$(BR_DIR):
	git clone --depth 1 --branch $(BR_VERSION) https://gitlab.com/buildroot.org/buildroot.git $@

$(OUT)/.config: $(BR_DIR) $(EXT)/configs/common.fragment $(EXT)/configs/$(BOARD).fragment
	@test -n "$(BASE)" || { echo "unknown BOARD=$(BOARD)"; exit 1; }
	$(MAKE) -C $(BR_DIR) O=$(OUT) BR2_EXTERNAL=$(EXT) $(BASE)
	$(BR_DIR)/support/kconfig/merge_config.sh -m -O $(OUT) $(OUT)/.config \
		$(EXT)/configs/common.fragment $(EXT)/configs/$(BOARD).fragment
	echo 'BR2_LINUX_KERNEL_CUSTOM_REPO_VERSION="$(KERNEL_REF)"' >> $(OUT)/.config
	$(MAKE) -C $(BR_DIR) O=$(OUT) BR2_EXTERNAL=$(EXT) olddefconfig

build: $(OUT)/.config
	$(MAKE) -C $(BR_DIR) O=$(OUT) BR2_EXTERNAL=$(EXT)

flash:
	@test -n "$(DEV)" || { echo "usage: make flash DEV=/dev/sdX"; exit 1; }
	host/flash.sh $(OUT)/images/sdcard.img $(DEV)

check:
	sh tests/lint.sh

clean:
	rm -rf $(OUT)

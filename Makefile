BOARD ?= imx8mp
BR_VERSION ?= 2024.08
BR_DIR ?= $(CURDIR)/buildroot
# DEBUG=1 builds the debug kernel variant (KASAN, lockdep, KFENCE, kmemleak)
OUT ?= $(CURDIR)/output/$(BOARD)$(if $(DEBUG),-debug)
EXT := $(CURDIR)/external

base-sk-am64b := ti_am64x_sk_defconfig
base-imx8mp := freescale_imx8mpevk_defconfig
BASE := $(base-$(BOARD))
DEBUG_FRAG := $(if $(DEBUG),$(EXT)/board/common/linux-debug.fragment)

.PHONY: build flash clean check mark-stable

$(BR_DIR):
	git clone --depth 1 --branch $(BR_VERSION) https://gitlab.com/buildroot.org/buildroot.git $@

$(OUT)/.config: $(BR_DIR) $(EXT)/configs/common.fragment $(EXT)/configs/$(BOARD).fragment $(DEBUG_FRAG)
	@test -n "$(BASE)" || { echo "unknown BOARD=$(BOARD)"; exit 1; }
	$(MAKE) -C $(BR_DIR) O=$(OUT) BR2_EXTERNAL=$(EXT) $(BASE)
	$(BR_DIR)/support/kconfig/merge_config.sh -m -O $(OUT) $(OUT)/.config \
		$(EXT)/configs/common.fragment $(EXT)/configs/$(BOARD).fragment
	$(if $(DEBUG),sed -i 's#^\(BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES=".*\)"#\1 $(DEBUG_FRAG)"#' $(OUT)/.config)
	$(MAKE) -C $(BR_DIR) O=$(OUT) BR2_EXTERNAL=$(EXT) olddefconfig

build: $(OUT)/.config
	host/record-commits.sh $(OUT)/manifest.txt
	$(MAKE) -C $(BR_DIR) O=$(OUT) BR2_EXTERNAL=$(EXT)

# Call after the board tests passed: records the tested commits as stable.
mark-stable:
	cp $(OUT)/manifest.txt stable/$(BOARD)$(if $(DEBUG),-debug).txt

flash:
	@test -n "$(DEV)" || test "$(FLASH_METHOD)" = uuu || { echo "usage: make flash DEV=/dev/sdX"; exit 1; }
	FLASH_METHOD=$(FLASH_METHOD) host/flash.sh $(OUT)/images/sdcard.img $(DEV)

check:
	sh tests/lint.sh
	sh tests/test-lib.sh

clean:
	rm -rf $(OUT)

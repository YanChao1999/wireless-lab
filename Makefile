BOARD ?= sk-am64b
BR_VERSION ?= 2024.08
BR_DIR ?= $(CURDIR)/buildroot
OUT ?= $(CURDIR)/output/$(BOARD)
EXT := $(CURDIR)/external

base-sk-am64b := ti_am64x_sk_defconfig
base-imx8mp := freescale_imx8mpevk_defconfig
BASE := $(base-$(BOARD))

.PHONY: build flash clean check

$(BR_DIR):
	git clone --depth 1 --branch $(BR_VERSION) https://gitlab.com/buildroot.org/buildroot.git $@

$(OUT)/.config: $(BR_DIR) $(EXT)/configs/common.fragment $(EXT)/configs/$(BOARD).fragment
	@test -n "$(BASE)" || { echo "unknown BOARD=$(BOARD)"; exit 1; }
	$(MAKE) -C $(BR_DIR) O=$(OUT) BR2_EXTERNAL=$(EXT) $(BASE)
	$(BR_DIR)/support/kconfig/merge_config.sh -m -O $(OUT) $(OUT)/.config \
		$(EXT)/configs/common.fragment $(EXT)/configs/$(BOARD).fragment
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

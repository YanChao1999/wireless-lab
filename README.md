# wireless-lab

An extra-thin Linux distro (Buildroot + BusyBox, initramfs-only rootfs) that
tracks the latest mainline kernel/drivers, plus a set of wireless (Wi-Fi, BLE)
and power-domain tests. Main goal: find general Linux wireless issues and
report them upstream.

## Boards

| Board        | Buildroot base defconfig       | Status  |
|--------------|--------------------------------|---------|
| TI SK-AM64B  | `ti_am64x_sk_defconfig`        | first   |
| NXP i.MX8MP  | `freescale_imx8mpevk_defconfig`| second  |

## Build / flash

    make BOARD=sk-am64b build      # fetches Buildroot, builds image
    make BOARD=sk-am64b flash DEV=/dev/sdX
    make BOARD=imx8mp   build

`BOARD` is `sk-am64b` or `imx8mp`. Board fragments live in
`external/configs/<board>.fragment`; common settings (BusyBox, initramfs,
mainline kernel, wireless tools) are in `external/configs/common.fragment`.

## Tests (run on target)

`/usr/bin/wl-test-all` runs everything in `/usr/bin/wl-test.d`:

- `10-wifi`  : wlan interface present, scan works, dmesg free of driver errors
- `20-ble`   : HCI controller present and powered, LE scan works
- `30-power` : runtime-PM / power-domain state and suspend sanity

Results are printed as `PASS`/`FAIL`/`SKIP`; attach `dmesg` output and the
kernel version when reporting upstream.

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

## Host-side control and AI reproducer

Flashing and power are handled by the host (`host/`), not the target:

- `host/power.sh on|off|cycle` drives the programmable power module.
  Pick a backend with `POWER_BACKEND=cmd|uhubctl|http|manual`
  (see the script header for the variables each one needs).
- `host/flash.sh <image> <dev>` flashes (`ASSUME_YES=1` for unattended use).
- `host/reproduce.sh <image> <dev> <serial-tty> [outdir]` flashes, power-cycles,
  boots, runs `wl-test-all` over serial and saves `console.log` and
  `results.txt`. It exits non-zero on any FAIL, so an AI agent can loop on it
  to reproduce and bisect wireless issues.

## Latest mainline stack

The kernel is built from Linus's `master` and the wifi/ble userspace
(`iw`, `hostap`/wpa_supplicant, `bluez`, `wireless-regdb`, `linux-firmware`)
from upstream git HEAD (`external/local.mk`). Wireless/BT/PM kernel options
are in `external/board/common/linux-wireless.fragment`. Pin any component for
a reproducible report, e.g. `make KERNEL_REF=v6.12 WL_BLUEZ_REF=<sha> build`
(`WL_IW_REF`, `WL_HOSTAP_REF`, `WL_REGDB_REF`, `WL_FW_REF`).

## CI

`.github/workflows/ci.yml`: `lint` (`make check`) and a per-board image `build`
run on GitHub-hosted runners. The `board-test` job runs `host/reproduce.sh` on a
self-hosted runner wired to the real board. To enable it: register a runner with
labels `self-hosted,wireless-lab,<board>`, export `FLASH_DEV`, `SERIAL_TTY` and
the `POWER_*` variables in the runner environment, then set the repository
variable `BOARD_CI_ENABLED=true`.

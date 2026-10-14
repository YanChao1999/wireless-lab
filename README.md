# wireless-lab

An extra-thin Linux distro (Buildroot + BusyBox, initramfs-only rootfs) that
tracks the latest mainline kernel/drivers, plus a set of wireless (Wi-Fi, BLE)
and power-domain tests. Main goal: find general Linux wireless issues and
report them upstream.

## Boards

| Board        | Buildroot base defconfig       | Status  |
|--------------|--------------------------------|---------|
| NXP i.MX8MP  | `freescale_imx8mpevk_defconfig`| first (default) |
| TI SK-AM64B  | `ti_am64x_sk_defconfig`        | second  |

## Build / flash

    make build                     # i.MX8MP (default); fetches Buildroot, builds image
    make flash DEV=/dev/sdX
    make FLASH_METHOD=uuu flash   # i.MX8MP over USB (uuu), no SD card
    make BOARD=sk-am64b build

i.MX8MP uses the NXP IW612 module. Bluetooth works with the mainline
`btnxpuart` driver; Wi-Fi has no mainline driver (NXP out-of-tree only), so on a
pure mainline kernel only the BLE tests apply and the Wi-Fi tests skip.

`BOARD` is `imx8mp` (default) or `sk-am64b`. Board fragments live in
`external/configs/<board>.fragment`; common settings (BusyBox, initramfs,
mainline kernel, wireless tools) are in `external/configs/common.fragment`.

## Tests (run on target)

A tiny shell suite: `/usr/lib/wl-test/lib.sh` gives every test the same
`PASS`/`FAIL`/`SKIP` output, config loading, a dmesg splat check and a slab/
kmemleak leak check. `/usr/bin/wl-test-all` runs `/usr/bin/wl-test.d/*` in order
and exits non-zero on any FAIL. The library itself is unit-tested on the host
(`tests/test-lib.sh`, part of `make check`).

| Test | What it does |
|------|--------------|
| `10-wifi` / `20-ble` / `30-power` | presence, scan, runtime-PM and genpd sanity |
| `40-wifi-cycle` | link down/up + scan, connect/disconnect, driver reload, leaks |
| `50-ble-cycle` | hci down/up, LE scan soak, LE connection soak, leaks |
| `60-runtime-pm` | wifi/BLE runtime-PM transitions |
| `65-suspend` | suspend/resume (rtcwake) with wifi and BLE active |
| `70-throughput` | iperf3 tx/rx against the fixed AP, with a floor |
| `90-dmesg` | fails the run on any WARN/BUG/Oops/KASAN/lockdep/kmemleak/hung task |

Each test also fails on kernel splats logged during its own run.

**Fixed targets**: set the dedicated AP, iperf3 server and BLE peripheral in
`/etc/wl-test.conf` (`external/board/common/overlay/etc/wl-test.conf`, all
options documented there). Tests needing a target skip when it is unset.

**Debug kernel**: `make DEBUG=1 BOARD=<b> build` adds
`external/board/common/linux-debug.fragment` (KASAN, KFENCE, lockdep, kmemleak,
hung-task detection) and builds into `output/<b>-debug`. Run the tests on both
the normal and the debug kernel.

Attach `dmesg` output and the build `manifest.txt` when reporting upstream.

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
from upstream git master/main (`external/local.mk`). Nothing is pinned.
Every build writes the upstream commit IDs it used to
`output/<board>/manifest.txt` (also uploaded by CI, together with the
wireless-lab commit). When the board tests pass, `make BOARD=<b> mark-stable`
copies it to `stable/<b>.txt`: the last known-good set of commits for that
board, to compare against when something regresses.

## CI

`.github/workflows/ci.yml`: `lint` (`make check`: `sh -n` plus shellcheck on all scripts) and a per-board image `build`
run on GitHub-hosted runners. The `board-test` job runs `host/reproduce.sh` on a
self-hosted runner wired to the real board. To enable it: register a runner with
labels `self-hosted,wireless-lab,<board>`, export `FLASH_DEV`, `SERIAL_TTY` and
the `POWER_*` variables in the runner environment, then set the repository
variable `BOARD_CI_ENABLED=true`.

### Flashing i.MX8MP with uuu

`FLASH_METHOD=uuu` (`host/flash-uuu.sh`) runs `uuu -b emmc_all imx-boot sdcard.img`
(`UUU_TARGET=sd_all` for the SD slot, `UUU_BOOTLOADER` to point at the
bootloader). The board must be in serial download mode with USB connected.
After flashing, it must boot normally (eMMC/SD boot mode) before
`host/reproduce.sh` power-cycles it, so switching boot mode has to be
automated (e.g. a relay or boot-mode GPIO on the power module) or done by hand.
Buildroot's i.MX8MP image must also provide the `imx-boot` file for this.

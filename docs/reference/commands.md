# Commands

## `oc.sh` (on the router)

Controls the runtime module. Run as root over SSH, from the folder that holds
both `oc.sh` and `mt7981_oc_hold.ko`.

```
sh ./oc.sh check | status | 1300 | <MHz> [seconds] [--risk]
```

| Command | What it does |
|---|---|
| `sh ./oc.sh check` | Platform and checksum checks only. Loads nothing, writes nothing. |
| `sh ./oc.sh status` | Shows whether the module is loaded, its state and the CPU temperature. |
| `sh ./oc.sh <MHz>` | Sets the clock until `1300`, a reboot or the thermal guard. |
| `sh ./oc.sh <MHz> <seconds>` | Same, and returns to stock after the timer. |
| `sh ./oc.sh <MHz> --risk` | Needed for clocks above 1700 MHz. |
| `sh ./oc.sh 1300` | Returns to stock, verifies and unloads the module. |

- **MHz:** integer from 1301 to 2000; above 1700 requires `--risk`.
- **Timer:** off by default; 30–1800 seconds; `0` means no timer.
- The checks need: root, an aarch64 OpenWrt `mediatek/filogic` system with both
  CPUs online, and `insmod`, `rmmod`, `jsonfilter`, `sha256sum`, `apk`, `awk`,
  `grep`.

::: warning
Experimental. A complete CPU freeze can't be repaired by software: power-cycle
the router. Never add `oc.sh` to startup.
:::

## `bl2/build-bl2.sh` (on a PC)

Builds a Cudy MT7981 ubootmod preloader with the OpenWrt SDK.

```
sh bl2/build-bl2.sh <openwrt-sdk-dir> <openwrt-source-dir> <variant> <MHz|stock> <out-dir>
```

| Argument | Meaning |
|---|---|
| `openwrt-sdk-dir` | Extracted `openwrt-sdk-<ver>-mediatek-filogic_*.tar.zst`, same release as your firmware |
| `openwrt-source-dir` | Git checkout of `openwrt` at the same tag (only the TF-A package is used) |
| `variant` | `cudy-ddr3`, `cudy-ddr4`, … |
| `MHz` or `stock` | Clock (multiple of 20, 1320–1800), or `stock` for the unmodified build |
| `out-dir` | Where the `.bin` is written |

Build `stock` first: it must be byte-identical to the official preloader. See
[Building](/building).

## `bl2/gen-patch.sh`

Prints the TF-A patch for one clock, for use in a full OpenWrt build tree
(`package/boot/arm-trusted-firmware-mediatek/patches/`).

```sh
sh bl2/gen-patch.sh 1600 > 900-mt7981-armpll-1600mhz.patch
```

MHz must be a multiple of 20 between 1320 and 1800.

## `runtime/build-module.sh`

Builds the runtime module against an SDK's kernel, checks vermagic and resolves
every imported symbol. Prints the SDK's kernel hash, which must match the
router's.

```sh
sh runtime/build-module.sh <openwrt-sdk-dir> <out-dir>
```

## `ci/build-release.sh`

Runs the whole release build locally, the same way the daily workflow does.

```sh
WORK=$PWD/work sh ci/build-release.sh 25.12.6 dist/
```

See [Automated builds](/automation).

## Useful commands on the router

| Command | Purpose |
|---|---|
| `cat /proc/mtd` | Partition list; `mtd0` should be `BL2` |
| `cat /sys/class/thermal/thermal_zone0/temp` | CPU temperature in millidegrees C |
| `apk add coremark && coremark \| grep Iterations/Sec` | Benchmark; should scale with MHz / 1300 |
| `apk add kmod-mtd-rw && insmod mtd-rw i_want_a_brick=1` | Makes BL2 writable until the next reboot |

# MT7981 CPU overclock for Cudy routers (OpenWrt ubootmod)

Overclock the MediaTek MT7981B (Filogic 820) in Cudy routers running OpenWrt with the
**OpenWrt U-Boot layout ("ubootmod")**, from the stock 1.3 GHz up to 1.4–1.7 GHz.

Two methods, meant to be used in this order:

1. **Runtime module** (`runtime/`): changes the clock while the router runs, nothing is
   written to flash, reboot = back to stock. Use it to find the highest clock your unit
   handles, with a 74 °C guard that drops back to stock.
2. **Overclocked preloader** (`bl2/`): the official OpenWrt BL2 rebuilt with only the CPU
   PLL setting changed. Permanent: survives reboots, factory resets and sysupgrades.

On a WR3000H v1: coremark 4355 → 5074 at 1.5 GHz (+16.5 %), 5430 at 1.6 GHz (+24.7 %).
See [docs/results.md](docs/results.md).

> [!WARNING]
> Overclocking is outside the chip's specification and is done at your own risk.
> The CPU voltage is not changed (there is no vcore control), which limits headroom.
> A preloader that hangs leaves the router unable to boot. The only fix is a
> 3.3 V USB-UART on the board and `mtk_uartboot` (see [docs/recovery.md](docs/recovery.md)).
> Test with the runtime module first.

## Supported devices

Prebuilt files are for **OpenWrt 25.12.6**. The official 25.12.6 preloader is
byte-identical across each group below, so one set of files covers the whole group.

| BL2 variant | Devices (`*-ubootmod` images only) | Official stock preloader sha256 | Tested |
|---|---|---|---|
| `cudy-ddr3` | WR3000H v1, WR3000S v1, WR3000E v1, TR3000 v1, M3000 v1/v2, M3000 v2 YT8821, WBR3000UAX v1 | `524f588d…ada472` | WR3000H v1 (BL2 1500, module 1500 & 1600) |
| `cudy-ddr4` | WR3000P v1 | `9be2b11c…5e5442` | **not tested on hardware** |

Not for the stock Cudy layout (non-ubootmod) or other brands. The runtime module works on
any MT7981 board whose clock registers read the expected stock values; it checks this and
refuses otherwise.

## Quick start

### 1. Find a stable clock with the runtime module

Only works while the **stock** preloader is installed.

```sh
scp -O -r runtime root@192.168.1.1:/root/mt7981-oc
ssh root@192.168.1.1
cd /root/mt7981-oc
cp prebuilt/25.12.6/mt7981_oc_hold.ko . && sha256sum mt7981_oc_hold.ko   # compare with prebuilt/25.12.6/SHA256SUMS
sh ./oc.sh check
sh ./oc.sh 1500 120                 # 1500 MHz, auto-return after 120 s
apk add coremark && coremark | grep Iterations/Sec
sh ./oc.sh 1300                     # back to stock
```

Then stress-test each step for an hour or more. Details: [docs/runtime-module.md](docs/runtime-module.md).

### 2. Make it permanent

```sh
dd if=/dev/mtd0 of=/tmp/bl2-backup.bin                    # mtd0 = "BL2" (check /proc/mtd)
head -c 230232 /tmp/bl2-backup.bin | sha256sum            # must match the official stock hash above
apk add kmod-mtd-rw && insmod mtd-rw i_want_a_brick=1
mtd write mt7981-cudy-ddr3-preloader-1600.bin BL2
mtd verify mt7981-cudy-ddr3-preloader-1600.bin BL2
reboot
```

Full procedure: [docs/bl2-flashing.md](docs/bl2-flashing.md).

## How it works

The MT7981 has no DVFS/cpufreq in OpenWrt. BL2 programs the CPU PLL (ARMPLL) once:

```
f_cpu = 40 MHz × PCW / 2^POSDIV        stock: PCW = 0x82 (130), POSDIV = 1 → 1300 MHz
                                       OC:    PCW = MHz/20,     POSDIV = 0
```

The patch (`bl2/patches/`) changes two lines in `plat/mediatek/mt7981/drivers/pll/pll.c`:

```c
mmio_write_32(ARMPLL_CON1, 0x50000000);            /* 1600 MHz, PCW = 0x50 */
mmio_clrsetbits_32(ARMPLL_CON0, 0x70, 0x104);      /* POSDIV field cleared → /1 */
```

The POSDIV field must be **cleared**. Its reset value is /2, so OR-ing in `0x104` alone gives
half the intended clock (see [CHANGELOG.md](CHANGELOG.md)).

Everything else is the stock OpenWrt build: an unpatched build with `bl2/build-bl2.sh` is
byte-identical to the official preloader for both variants.

## Repository layout

```
bl2/
  patches/                 ATF patches for 1400/1500/1600/1700 MHz
  gen-patch.sh             generate a patch for any multiple of 20 MHz (1320–1800)
  build-bl2.sh             build any variant/clock with the OpenWrt SDK
  prebuilt/25.12.6/        cudy-ddr3 / cudy-ddr4 preloaders (stock + OC) and SHA256SUMS
runtime/
  oc.sh                    control script (check / status / 1300 / <MHz> [seconds] [--risk])
  source/                  kernel module source (upstream, unmodified)
  build-module.sh          build the module against an SDK's kernel
  prebuilt/25.12.6/        mt7981_oc_hold.ko for kernel 6.12.112 (25.12.6)
docs/                      flashing, runtime module, recovery, building, results
```

## Other OpenWrt versions

The prebuilt preloader doesn't depend on the kernel, but rebuild it for your release anyway
so it matches the U-Boot (FIP) you have. The prebuilt module only loads on kernel 6.12.112
(25.12.6). For anything else see [docs/building.md](docs/building.md).

## Credits

* Runtime module: Dystopian/openwrt-mt7981-overclock, a fork of
  rison1337/wr3000s-openwrt-overclock (GPL-2.0-only). Included unmodified.
* PLL programming approach: WuSiYu's OpenWrt One BL2 overclock write-up and the
  hanwckf / Yuzhii0718 bl-mt798x projects (whose code clears the POSDIV field).
* OpenWrt and mtk-openwrt/arm-trusted-firmware.

## License

* `bl2/`: patches and scripts under BSD-3-Clause, the same license as TF-A
  (`LICENSES/BSD-3-Clause-TF-A.rst`). The prebuilt preloaders are TF-A builds that include
  MediaTek's prebuilt DRAM init object, as shipped by OpenWrt.
* `runtime/`: GPL-2.0-only (`runtime/LICENSE`, `LICENSES/GPL-2.0-only.txt`).

No warranty. Not affiliated with Cudy, MediaTek or OpenWrt.

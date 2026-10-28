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
ci/                        release automation (detect new OpenWrt release, build, verify)
.github/workflows/         daily build workflow
docs/                      flashing, runtime module, recovery, building, automation, results
```

## Other OpenWrt versions

The prebuilt preloader doesn't depend on the kernel, but rebuild it for your release anyway
so it matches the U-Boot (FIP) you have. The prebuilt module only loads on kernel 6.12.112
(25.12.6). For anything else see [docs/building.md](docs/building.md).

## Automated builds

`.github/workflows/build-release.yml` checks the OpenWrt download server daily. When a new
stable release (25.12.0 or later) appears, it builds and publishes an `oc-<version>` release.
Each variant's stock preloader must first rebuild byte-identical to the official one, or
nothing is published. See [docs/automation.md](docs/automation.md).

## Credits

* Runtime module: [Dystopian/openwrt-mt7981-overclock](https://github.com/Dystopian/openwrt-mt7981-overclock),
  a fork of [rison1337/wr3000s-openwrt-overclock](https://github.com/rison1337/wr3000s-openwrt-overclock)
  (GPL-2.0-only). Included unmodified.
* PLL programming approach: [WuSiYu's OpenWrt One BL2 overclock guide](https://wusiyu.me/openwrt-one-mt7981-bl2-overclocking-compile-guide/)
  and the [hanwckf/bl-mt798x](https://github.com/hanwckf/bl-mt798x) /
  [Yuzhii0718/bl-mt798x-dhcpd](https://github.com/Yuzhii0718/bl-mt798x-dhcpd) projects
  (whose code clears the POSDIV field).
* [OpenWrt](https://github.com/openwrt/openwrt) and
  [mtk-openwrt/arm-trusted-firmware](https://github.com/mtk-openwrt/arm-trusted-firmware).

## References

Everything used to research, build and verify this project.

**OpenWrt release files (25.12.6, mediatek/filogic)**
- Firmware selector, Cudy WR3000H v1 ubootmod: https://firmware-selector.openwrt.org/?version=25.12.6&target=mediatek%2Ffilogic&id=cudy_wr3000h-v1-ubootmod
- Release directory (official preloaders, U-Boot FIP, RAM BL2 for recovery, SDK, `sha256sums`): https://downloads.openwrt.org/releases/25.12.6/targets/mediatek/filogic/
- SDK: https://downloads.openwrt.org/releases/25.12.6/targets/mediatek/filogic/openwrt-sdk-25.12.6-mediatek-filogic_gcc-14.3.0_musl.Linux-x86_64.tar.zst
- Kernel modules (kernel 6.12.112, hash `f0a7348f…`; `kmod-mtd-rw`): https://downloads.openwrt.org/releases/25.12.6/targets/mediatek/filogic/kmods/6.12.112-1-f0a7348f9cb959e1bf4d0447669b031e/
- Packages (`coremark`): https://downloads.openwrt.org/releases/25.12.6/packages/aarch64_cortex-a53/packages/

**OpenWrt source**
- Repository (tag `v25.12.6`): https://github.com/openwrt/openwrt
- Device and preloader definitions: https://github.com/openwrt/openwrt/blob/openwrt-25.12/target/linux/mediatek/image/filogic.mk
- TF-A package (variants `mt7981-cudy-ddr3` / `mt7981-cudy-ddr4`, FIP offset, DDR settings): https://github.com/openwrt/openwrt/blob/openwrt-25.12/package/boot/arm-trusted-firmware-mediatek/Makefile
- WR3000H ubootmod device tree: https://github.com/openwrt/openwrt/blob/openwrt-25.12/target/linux/mediatek/dts/mt7981b-cudy-wr3000h-v1-ubootmod.dts
- Cudy NAND partition layout (BL2 partition): https://github.com/openwrt/openwrt/blob/openwrt-25.12/target/linux/mediatek/dts/mt7981b-cudy-wr3000-nand.dtsi

**Trusted Firmware-A (MediaTek)**
- mtk-openwrt/arm-trusted-firmware, commit used by OpenWrt 25.12: https://github.com/mtk-openwrt/arm-trusted-firmware/tree/78a0dfd927bb00ce973a1f8eb4079df0f755887a
- MT7981 PLL init patched here: https://github.com/mtk-openwrt/arm-trusted-firmware/blob/78a0dfd927bb00ce973a1f8eb4079df0f755887a/plat/mediatek/mt7981/drivers/pll/pll.c

**Overclocking prior work**
- Runtime overclock module: https://github.com/Dystopian/openwrt-mt7981-overclock
- Its build notes (register addresses, PLL math): https://github.com/Dystopian/openwrt-mt7981-overclock/blob/main/source/BUILD.md
- Original WR3000S project: https://github.com/rison1337/wr3000s-openwrt-overclock
- WuSiYu, OpenWrt One (MT7981) BL2 overclock guide: https://wusiyu.me/openwrt-one-mt7981-bl2-overclocking-compile-guide/
- Same guide on the Right.com.cn forum (1.7 GHz on OpenWrt One, crash at ~1.76 GHz): https://www.right.com.cn/forum/thread-8409872-1-1.html
- MT798X 1.65 GHz BL2 overclock thread (Right.com.cn): https://www.right.com.cn/forum/thread-8387979-1-1.html
- Yuzhii0718/bl-mt798x-dhcpd (OC profiles, POSDIV handling): https://github.com/Yuzhii0718/bl-mt798x-dhcpd
- Tzzssn/bl-mt798x-dhcpd (fork, OC/VARIANT build options): https://github.com/Tzzssn/bl-mt798x-dhcpd
- hanwckf/bl-mt798x: https://github.com/hanwckf/bl-mt798x
- Example CI-built 1.6 GHz DDR3 BL2 (generic layout, not for Cudy ubootmod): https://github.com/wgworldpy/bl-mt798x-dhcpd/releases/tag/2026.10.20-1909-bl2-preloader

**Hardware and tools**
- MT7981B datasheet (open version, rated 1.3 GHz): https://one.openwrt.org/hardware/MT7981B_Wi-Fi6_Platform_Datasheet_Open_V1.0.pdf
- mtk_uartboot (serial recovery): https://github.com/981213/mtk_uartboot
- OpenWrt forum: no cpufreq/DVFS on Filogic SoCs: https://forum.openwrt.org/t/redmi-ax6000-possible-to-build-cpu-governor-into-kernel/143755

## License

* `bl2/`: patches and scripts under BSD-3-Clause, the same license as TF-A
  (`LICENSES/BSD-3-Clause-TF-A.rst`). The prebuilt preloaders are TF-A builds that include
  MediaTek's prebuilt DRAM init object, as shipped by OpenWrt.
* `runtime/`: GPL-2.0-only (`runtime/LICENSE`, `LICENSES/GPL-2.0-only.txt`).

No warranty. Not affiliated with Cudy, MediaTek or OpenWrt.

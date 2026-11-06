# References and credits

## Credits

- **Runtime module:** [Dystopian/openwrt-mt7981-overclock](https://github.com/Dystopian/openwrt-mt7981-overclock),
  a fork of [rison1337/wr3000s-openwrt-overclock](https://github.com/rison1337/wr3000s-openwrt-overclock)
  (GPL-2.0-only). Included unmodified.
- **PLL programming approach:** [WuSiYu's OpenWrt One BL2 overclock guide](https://wusiyu.me/openwrt-one-mt7981-bl2-overclocking-compile-guide/)
  and the [hanwckf/bl-mt798x](https://github.com/hanwckf/bl-mt798x) /
  [Yuzhii0718/bl-mt798x-dhcpd](https://github.com/Yuzhii0718/bl-mt798x-dhcpd)
  projects (whose code clears the POSDIV field).
- [OpenWrt](https://github.com/openwrt/openwrt) and
  [mtk-openwrt/arm-trusted-firmware](https://github.com/mtk-openwrt/arm-trusted-firmware).

## OpenWrt release files (25.12.6, mediatek/filogic)

- [Firmware selector, Cudy WR3000H v1 ubootmod](https://firmware-selector.openwrt.org/?version=25.12.6&target=mediatek%2Ffilogic&id=cudy_wr3000h-v1-ubootmod)
- [Release directory](https://downloads.openwrt.org/releases/25.12.6/targets/mediatek/filogic/): official preloaders, U-Boot FIP, RAM BL2 for recovery, SDK, `sha256sums`
- [SDK](https://downloads.openwrt.org/releases/25.12.6/targets/mediatek/filogic/openwrt-sdk-25.12.6-mediatek-filogic_gcc-14.3.0_musl.Linux-x86_64.tar.zst)
- [Kernel modules](https://downloads.openwrt.org/releases/25.12.6/targets/mediatek/filogic/kmods/6.12.112-1-f0a7348f9cb959e1bf4d0447669b031e/) (kernel 6.12.112, `kmod-mtd-rw`)
- [Packages](https://downloads.openwrt.org/releases/25.12.6/packages/aarch64_cortex-a53/packages/) (`coremark`)

## OpenWrt source

- [Repository](https://github.com/openwrt/openwrt) (tag `v25.12.6`)
- [Device and preloader definitions](https://github.com/openwrt/openwrt/blob/openwrt-25.12/target/linux/mediatek/image/filogic.mk) (`filogic.mk`)
- [TF-A package](https://github.com/openwrt/openwrt/blob/openwrt-25.12/package/boot/arm-trusted-firmware-mediatek/Makefile): variants `mt7981-cudy-ddr3` / `mt7981-cudy-ddr4`, FIP offset, DDR settings
- [WR3000H ubootmod device tree](https://github.com/openwrt/openwrt/blob/openwrt-25.12/target/linux/mediatek/dts/mt7981b-cudy-wr3000h-v1-ubootmod.dts)
- [Cudy NAND partition layout](https://github.com/openwrt/openwrt/blob/openwrt-25.12/target/linux/mediatek/dts/mt7981b-cudy-wr3000-nand.dtsi) (BL2 partition)

## Trusted Firmware-A (MediaTek)

- [mtk-openwrt/arm-trusted-firmware, commit used by OpenWrt 25.12](https://github.com/mtk-openwrt/arm-trusted-firmware/tree/78a0dfd927bb00ce973a1f8eb4079df0f755887a)
- [MT7981 PLL init patched here](https://github.com/mtk-openwrt/arm-trusted-firmware/blob/78a0dfd927bb00ce973a1f8eb4079df0f755887a/plat/mediatek/mt7981/drivers/pll/pll.c) (`pll.c`)

## Overclocking prior work

- [Runtime overclock module](https://github.com/Dystopian/openwrt-mt7981-overclock) and its [build notes](https://github.com/Dystopian/openwrt-mt7981-overclock/blob/main/source/BUILD.md) (register addresses, PLL math)
- [Original WR3000S project](https://github.com/rison1337/wr3000s-openwrt-overclock)
- [WuSiYu, OpenWrt One (MT7981) BL2 overclock guide](https://wusiyu.me/openwrt-one-mt7981-bl2-overclocking-compile-guide/), also on the [Right.com.cn forum](https://www.right.com.cn/forum/thread-8409872-1-1.html) (1.7 GHz on OpenWrt One, crash at ~1.76 GHz)
- [MT798X 1.65 GHz BL2 overclock thread](https://www.right.com.cn/forum/thread-8387979-1-1.html) (Right.com.cn)
- [Yuzhii0718/bl-mt798x-dhcpd](https://github.com/Yuzhii0718/bl-mt798x-dhcpd) (OC profiles, POSDIV handling)
- [Tzzssn/bl-mt798x-dhcpd](https://github.com/Tzzssn/bl-mt798x-dhcpd) (fork, OC/VARIANT build options)
- [hanwckf/bl-mt798x](https://github.com/hanwckf/bl-mt798x)
- [Example CI-built 1.6 GHz DDR3 BL2](https://github.com/wgworldpy/bl-mt798x-dhcpd/releases/tag/2026.10.20-1909-bl2-preloader) (generic layout, **not** for Cudy ubootmod)

## Hardware and tools

- [MT7981B datasheet](https://one.openwrt.org/hardware/MT7981B_Wi-Fi6_Platform_Datasheet_Open_V1.0.pdf) (open version, rated 1.3 GHz)
- [mtk_uartboot](https://github.com/981213/mtk_uartboot) (serial recovery)
- [OpenWrt forum: no cpufreq/DVFS on Filogic SoCs](https://forum.openwrt.org/t/redmi-ax6000-possible-to-build-cpu-governor-into-kernel/143755)

## License

- `bl2/`: patches and scripts under BSD-3-Clause, the same license as TF-A. The
  prebuilt preloaders are TF-A builds that include MediaTek's prebuilt DRAM init
  object, as shipped by OpenWrt.
- `runtime/`: GPL-2.0-only.

No warranty. Not affiliated with Cudy, MediaTek or OpenWrt.

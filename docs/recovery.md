# Recovery from a preloader that doesn't boot

Symptoms: no LEDs past power-on, no network, after flashing a new BL2. The MT7981 BootROM
only falls back when the BL2 header is invalid. A BL2 that hangs while setting the PLL
isn't detected, so a power cycle doesn't help.

Your OpenWrt install, settings and U-Boot (FIP) are untouched; only BL2 needs fixing.

## You need

* 3.3 V USB-UART adapter (GND, TX, RX only; don't connect VCC), on the board's serial
  pads, 115200 8N1.
* `mtk_uartboot` (981213/mtk_uartboot).
* From the OpenWrt release directory for your version (mediatek/filogic):
  * the RAM BL2: `mt7981-ram-ddr3-bl2.bin` (cudy-ddr3) or `mt7981-ram-ddr4-bl2.bin` (cudy-ddr4)
  * your device's `openwrt-<ver>-mediatek-filogic-<device>-ubootmod-bl31-uboot.fip`

## Steps

1. Router **off**. On the PC:

   ```sh
   mtk_uartboot -s /dev/ttyUSB0 --aarch64 \
     -p mt7981-ram-ddr3-bl2.bin \
     -f openwrt-25.12.6-mediatek-filogic-cudy_wr3000h-v1-ubootmod-bl31-uboot.fip
   ```
2. Power the router on. The stock RAM BL2 (1.3 GHz) and U-Boot load over serial.
3. Open a serial terminal at 115200 to get the U-Boot menu and boot the system from flash.
4. In OpenWrt, flash the stock preloader (or a lower clock) as in
   [bl2-flashing.md](bl2-flashing.md), or restore your `bl2-backup.bin`.

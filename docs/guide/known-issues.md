# Known issues

## System time and NTP after overclocking

::: danger Affects WireGuard and other encrypted services
Changing the CPU clock speed affects the system time and NTP. Services that rely
on correct time, such as WireGuard and other modules that use encryption, can
stop working as intended.
:::

The fix is to tell the kernel the new CPU frequency in the device tree, then
build a sysupgrade image with the OpenWrt **Image Builder** for your release.

1. Download and unpack the Image Builder for your release and target, for
   example `openwrt-imagebuilder-25.12.6-mediatek-filogic.Linux-x86_64.tar.zst`
   from the OpenWrt release directory.
2. Add this to the end of your device's ubootmod device tree, for example
   `target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1-ubootmod.dts`:

   ```dts
   &cpu0 {
   	clock-frequency = <1700000000>; // change to the clock you flashed
   };

   &cpu1 {
   	clock-frequency = <1700000000>;
   };
   ```
3. Build the image for your device's profile:

   ```sh
   make image PROFILE=cudy_tr3000-v1-ubootmod
   ```
4. The new sysupgrade image is in `bin/targets/mediatek/filogic/` inside the
   Image Builder folder. Install it with sysupgrade as usual.

Replace the TR3000 file and profile with your device's (the names are listed in
`target/linux/mediatek/image/filogic.mk`), and the frequency with the clock of
the preloader you flashed, in Hz.

## v1 preloaders run at half speed

v1 preloaders set the divider with `mmio_setbits_32(..., 0x104)`. The POSDIV
field's reset value is /2, so they ran at **half** the target: v1 "1500" ran at
750 MHz (coremark 2539 vs 4355 at stock). v2 clears the field first.

v1 files were never published in this repository. If you have them from
elsewhere, don't use them. A coremark score **below stock** after flashing is
the sign of a wrong clock: reflash.

## No thermal guard once flashed

The runtime module drops back to stock at 74 °C; a flashed preloader can't.
Check the temperature now and then:

```sh
cat /sys/class/thermal/thermal_zone0/temp     # millidegrees C
```

## The runtime module refuses to load

- It only works with the **stock** preloader. With an overclocked BL2 the
  registers aren't at stock values, and the module refuses (no writes).
- It must match your exact kernel. The prebuilt one is for OpenWrt 25.12.6
  (kernel 6.12.112). For other releases use the matching `oc-<version>` release
  or [build it](/building#runtime-module).

## A freeze while testing

Pull the power: the router boots at stock, because the module is never started
automatically. Use the previous clock step. **Never add the module to startup**:
a freeze at boot would become a boot loop.

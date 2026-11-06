# Getting started

This project overclocks the CPU of Cudy routers based on the MediaTek MT7981B
(Filogic 820) that run OpenWrt with the **OpenWrt U-Boot layout ("ubootmod")**.
The stock clock is 1.3 GHz; most units handle 1.4–1.7 GHz.

## Two methods, in this order

| | Runtime module | Overclocked preloader (BL2) |
|---|---|---|
| What | Kernel module that reprograms the CPU clock while the router runs | Official OpenWrt preloader rebuilt with only the CPU PLL setting changed |
| Writes to flash | No | Yes, the BL2 partition |
| After a reboot | Back to stock | Stays overclocked |
| Survives sysupgrade and factory reset | — | Yes |
| Thermal guard | Yes, drops to stock at 74 °C | No |
| Use it to | Find the highest stable clock for **your** unit | Keep that clock permanently |

The module programs exactly the same register values as the preloader, so a
clock that's stable with the module behaves the same from boot.

## Before you start

- Check that your router is listed under [Supported devices](/guide/supported-devices)
  and runs a `*-ubootmod` image of the matching OpenWrt release (prebuilt files:
  **25.12.6**).
- Read [Known issues](/guide/known-issues): changing the clock affects the
  system time, which matters for WireGuard and other encrypted services.
- For the permanent step, have a **3.3 V USB-UART adapter** and know where your
  board's serial pads are. It's the only way back if a preloader doesn't boot
  ([Recovery](/recovery)).

## Get the files

- The [latest release](https://github.com/miercolesv/mt7981-cudy-overclock/releases)
  has the preloaders, the runtime module and `SHA256SUMS` for the newest
  supported OpenWrt release.
- Or clone the repository; prebuilt files for 25.12.6 are in
  `bl2/prebuilt/25.12.6/` and `runtime/prebuilt/25.12.6/`.

```sh
git clone https://github.com/miercolesv/mt7981-cudy-overclock.git
cd mt7981-cudy-overclock
```

## 1. Find a stable clock

Runs only while the **stock** preloader is installed.

```sh
scp -O -r runtime root@192.168.1.1:/root/mt7981-oc
ssh root@192.168.1.1
cd /root/mt7981-oc
cp prebuilt/25.12.6/mt7981_oc_hold.ko . && sha256sum mt7981_oc_hold.ko   # compare with prebuilt/25.12.6/SHA256SUMS
sh ./oc.sh check
sh ./oc.sh 1500 120                 # 1500 MHz, back to stock after 120 s
apk add coremark && coremark | grep Iterations/Sec
sh ./oc.sh 1300                     # back to stock
```

Then stress-test each step for an hour or more, going up 100 MHz at a time.
Details: [Runtime module](/runtime-module).

## 2. Make it permanent

```sh
dd if=/dev/mtd0 of=/tmp/bl2-backup.bin                    # mtd0 = "BL2" (check /proc/mtd)
head -c 230232 /tmp/bl2-backup.bin | sha256sum            # must match the official stock hash
apk add kmod-mtd-rw && insmod mtd-rw i_want_a_brick=1
mtd write mt7981-cudy-ddr3-preloader-1600.bin BL2
mtd verify mt7981-cudy-ddr3-preloader-1600.bin BL2
reboot
```

Use the file for your variant and the clock you tested. Full procedure,
including the stock hashes: [Flashing the preloader](/bl2-flashing).

## 3. Check the result

```sh
apk add coremark
coremark | grep Iterations/Sec
```

The score should be roughly stock × (MHz / 1300). Less than stock means the
clock is wrong: reflash. See [Results](/results) for reference numbers.

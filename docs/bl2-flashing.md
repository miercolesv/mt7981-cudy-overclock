# Flashing an overclocked preloader (BL2)

Applies to the devices in the README table, running the matching OpenWrt release
(prebuilt files: 25.12.6) with the ubootmod layout.

## Before you start

* Find a stable clock with the runtime module first ([runtime-module.md](runtime-module.md)).
  The module programs exactly the same register values as the preloader, so a clock that's
  stable with the module will behave the same from boot.
* Have a 3.3 V USB-UART and know where your board's serial pads are. If a preloader hangs,
  that's the only way back ([recovery.md](recovery.md)).
* Unload the runtime module first (`sh ./oc.sh 1300`). Don't flash while it's active.
* Once flashed there's **no thermal guard**. Check temperature occasionally:
  `cat /sys/class/thermal/thermal_zone0/temp` (millidegrees C).

## 1. Identify and back up your current preloader

```sh
cat /proc/mtd                          # mtd0 should be "BL2", size 00100000
dd if=/dev/mtd0 of=/tmp/bl2-backup.bin
head -c 230232 /tmp/bl2-backup.bin | sha256sum
```

| Variant | Expected stock hash (25.12.6) |
|---|---|
| cudy-ddr3 | `524f588dabb7c23dcecf148e793721ad4e451041acf124694486312e86ada472` |
| cudy-ddr4 | `9be2b11ca74912f29ef984e33b8ced740a9bdb02411ba9dcb9b464bcf53e5442` |

If it doesn't match, you're running a different preloader (another release, or the wrong
variant). **Stop** and rebuild for your release ([building.md](building.md)).
Copy the backup to your PC:

```sh
scp -O root@192.168.1.1:/tmp/bl2-backup.bin .
```

## 2. Flash

```sh
# PC
scp -O bl2/prebuilt/25.12.6/cudy-ddr3/mt7981-cudy-ddr3-preloader-1600.bin root@192.168.1.1:/tmp/

# router
cd /tmp
sha256sum mt7981-cudy-ddr3-preloader-1600.bin    # compare with SHA256SUMS
apk add kmod-mtd-rw                              # BL2 is read-only in the device tree
insmod mtd-rw i_want_a_brick=1
mtd write mt7981-cudy-ddr3-preloader-1600.bin BL2
mtd verify mt7981-cudy-ddr3-preloader-1600.bin BL2
reboot
```

`mtd-rw` has to be loaded again after every reboot. Installing it doesn't load it.

## 3. Verify

```sh
apk add coremark
coremark | grep Iterations/Sec
```

Expect roughly stock × (MHz / 1300). If you get *less* than stock, the clock is wrong:
don't keep it, reflash.

## Going back / changing clock

Flash `...-preloader-stock.bin` (or another clock) the same way. sysupgrade on the ubootmod
layout only rewrites UBI and never touches BL2, so the overclock stays until you reflash it.

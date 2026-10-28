# Changelog

## v2 (current)

* Fix: clear the ARMPLL_CON0 POSDIV field before selecting /1
  (`mmio_clrsetbits_32(ARMPLL_CON0, 0x70, 0x104)`). v1 used `mmio_setbits_32(..., 0x104)`;
  the field's reset value is /2, so v1 preloaders ran at **half** the target
  (v1 "1500" = 750 MHz, coremark 2539 vs 4355 stock). v1 files were never published here.
  If you have them from elsewhere, don't use them.
* Added `cudy-ddr4` (WR3000P v1) preloaders. Not tested on hardware.
* Build scripts: `bl2/build-bl2.sh`, `bl2/gen-patch.sh`, `runtime/build-module.sh`.

## v1

* `cudy-ddr3` preloaders 1400–1700 MHz for OpenWrt 25.12.6 (POSDIV bug, see above).

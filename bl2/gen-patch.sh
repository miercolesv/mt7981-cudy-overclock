#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause
# Generate an ARMPLL overclock patch for OpenWrt's arm-trusted-firmware-mediatek
# (mtk-openwrt ATF @ 78a0dfd9, as used by OpenWrt 25.12.x).
# Usage: gen-patch.sh <MHz>   (multiple of 20, 1320..1800) > 900-mt7981-armpll-<MHz>mhz.patch
set -eu
mhz=${1:?MHz}
case "$mhz" in ''|*[!0-9]*) echo "MHz must be an integer" >&2; exit 1;; esac
[ "$mhz" -ge 1320 ] && [ "$mhz" -le 1800 ] || { echo "MHz must be 1320..1800" >&2; exit 1; }
[ $((mhz % 20)) -eq 0 ] || { echo "MHz must be a multiple of 20 (integer PCW)" >&2; exit 1; }
hex=$(printf '%02X' $((mhz / 20)))
cat <<PATCH
--- a/plat/mediatek/mt7981/drivers/pll/pll.c
+++ b/plat/mediatek/mt7981/drivers/pll/pll.c
@@ -94,11 +94,11 @@ void mtk_pll_init(int skip_dcm_setting)
 	mmio_clrbits_32(MPLL_PWR_CON0, CON0_ISO_EN);
 
 	/* Set PLL frequency */
-	mmio_write_32(ARMPLL_CON1, 0x82000000); /* 1.3G */
+	mmio_write_32(ARMPLL_CON1, 0x${hex}000000); /* ${mhz} MHz with POSDIV=/1 (OC) */
 
 	//mmio_setbits_32(ARMPLL_CON0, 0x124); /* divider for 650M */
 
-	mmio_setbits_32(ARMPLL_CON0, 0x114); /* divider for 1.3G */
+	mmio_clrsetbits_32(ARMPLL_CON0, 0x70, 0x104); /* clear POSDIV field (reset value is /2), set /1 */
 
 	mmio_setbits_32(NET2PLL_CON0, 0x114);
 	mmio_setbits_32(MMPLL_CON0, 0x124);
PATCH

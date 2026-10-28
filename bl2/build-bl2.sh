#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause
# Build a Cudy MT7981 ubootmod preloader (BL2) with the OpenWrt SDK.
#
# Usage: build-bl2.sh <openwrt-sdk-dir> <openwrt-source-dir> <cudy-ddr3|cudy-ddr4|...> <MHz|stock> <out-dir>
#   openwrt-sdk-dir     extracted openwrt-sdk-<ver>-mediatek-filogic_*.tar.zst (same release as your firmware)
#   openwrt-source-dir  git checkout of openwrt at the same tag (only package/boot/arm-trusted-firmware-mediatek is used)
#
# Build "stock" first and compare it with the official ...-ubootmod-preloader.bin for your device:
# it should be byte-identical. That proves the toolchain/inputs match before you build an OC one.
set -eu
sdk=$(cd "${1:?sdk dir}" && pwd -P)
src=$(cd "${2:?openwrt source dir}" && pwd -P)
variant=${3:?variant, e.g. cudy-ddr3}
mhz=${4:?MHz or stock}
out=${5:?out dir}
here=$(cd "$(dirname "$0")" && pwd -P)

case "$variant" in cudy-*) ;; *) echo "variant must be a Cudy TF-A variant (cudy-ddr3, cudy-ddr4, ...)" >&2; exit 1;; esac

pkg="$sdk/package/arm-trusted-firmware-mediatek"
rm -rf "$pkg"
cp -r "$src/package/boot/arm-trusted-firmware-mediatek" "$pkg"
# Make the per-board TF-A variants selectable in the SDK and build only the one we need.
sed -i 's/^  HIDDEN:=y$/  HIDDEN:=/' "$pkg/Makefile"
awk -v t="mt7981-$variant" '
	/^TFA_TARGETS:= \\$/ { print "TFA_TARGETS:= " t; skip=1; next }
	skip && /^$/ { skip=0 }
	!skip { print }' "$pkg/Makefile" > "$pkg/Makefile.new"
mv "$pkg/Makefile.new" "$pkg/Makefile"

if [ "$mhz" != stock ]; then
	sh "$here/gen-patch.sh" "$mhz" > "$pkg/patches/900-mt7981-armpll-${mhz}mhz.patch"
fi

cd "$sdk"
[ -f .config ] || make defconfig >/dev/null
sym="CONFIG_PACKAGE_trusted-firmware-a-mt7981-$variant=y"
grep -qx "$sym" .config || { echo "$sym" >> .config; make defconfig >/dev/null; }
grep -qx "$sym" .config || { echo "could not select $sym" >&2; exit 1; }

make package/arm-trusted-firmware-mediatek/clean >/dev/null 2>&1 || true
make package/arm-trusted-firmware-mediatek/compile -j"$(nproc)"

img=$(ls staging_dir/target-*/image/mt7981-"$variant"-bl2.img)
mkdir -p "$out"
dst="$out/mt7981-$variant-preloader-$mhz.bin"
cp "$img" "$dst"
sha256sum "$dst"

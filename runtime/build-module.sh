#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
# Build mt7981_oc_hold.ko against the exact OpenWrt kernel of an SDK.
# Usage: build-module.sh <openwrt-sdk-dir> <out-dir>
# The SDK must be from the SAME release as the router's firmware (kernel version + kernel hash).
set -eu
sdk=$(cd "${1:?sdk dir}" && pwd -P)
out=${2:?out dir}
here=$(cd "$(dirname "$0")" && pwd -P)

kdir=$(dirname "$(find "$sdk/build_dir" -type f -path '*/linux-mediatek_filogic/linux-*/Module.symvers' -print -quit)")
[ -f "$kdir/Module.symvers" ] || { echo "kernel build tree not found in SDK" >&2; exit 1; }
gcc=$(find "$sdk/staging_dir" -type f -name 'aarch64-openwrt-linux-musl-gcc' -print -quit)
[ -n "$gcc" ] || { echo "cross compiler not found in SDK" >&2; exit 1; }
cross=${gcc%gcc}
export STAGING_DIR="$(ls -d "$sdk"/staging_dir/target-aarch64_*)"

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT INT TERM
cp "$here/source/mt7981_oc_hold.c" "$here/source/mt7981_oc_freq.h" "$here/source/Makefile" "$work/"
make -C "$kdir" M="$work" ARCH=arm64 CROSS_COMPILE="$cross" HOSTCC=gcc modules

release=$(make -s -C "$kdir" ARCH=arm64 CROSS_COMPILE="$cross" kernelrelease)
vermagic=$(modinfo -F vermagic "$work/mt7981_oc_hold.ko")
case "$vermagic" in "$release "*) ;; *) echo "vermagic mismatch: $vermagic vs $release" >&2; exit 1;; esac
"${cross}nm" -u "$work/mt7981_oc_hold.ko" | awk '{print $2}' | while read -r s; do
	awk -v n="$s" '$2==n{f=1} END{exit !f}' "$kdir/Module.symvers" || { echo "unresolved symbol: $s" >&2; exit 1; }
done
hash=$(grep -o "[0-9a-f]\{32\}" "$sdk/include/kernel.mk" 2>/dev/null | head -1 || true)
mkdir -p "$out"
cp "$work/mt7981_oc_hold.ko" "$out/"
echo "kernel: $release  vermagic: $vermagic  sdk kernel hash: ${hash:-unknown}"
sha256sum "$out/mt7981_oc_hold.ko"

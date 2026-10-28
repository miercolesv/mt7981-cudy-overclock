#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause
# Print the newest stable OpenWrt release (>= MIN_VERSION) whose mediatek/filogic
# directory is fully published (sha256sums lists an SDK). Prints nothing if none.
set -eu
min=${MIN_VERSION:-25.12.0}
mirror=${OPENWRT_MIRROR:-https://downloads.openwrt.org}
curl -fsSL "$mirror/releases/" |
	grep -o 'href="[0-9]*\.[0-9]*\.[0-9]*/"' | sed 's/^href="//; s/\/"$//' |
	{ cat; echo "$min"; } | sort -uV | awk -v m="$min" 'f; $0==m {f=1; print}' |
	sort -rV | while read -r v; do
		if curl -fsSL "$mirror/releases/$v/targets/mediatek/filogic/sha256sums" 2>/dev/null |
			grep -q 'openwrt-sdk-.*\.tar\.zst'; then
			echo "$v"; break
		fi
	done

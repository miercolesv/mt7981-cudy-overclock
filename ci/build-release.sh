#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause
# Build all Cudy MT7981 OC preloaders + runtime module for one OpenWrt release.
#
# Usage: build-release.sh <openwrt-version> <out-dir>
# Env:   CLOCKS="1400 1500 1600 1700"   WORK=<cache dir>   PREV_SUMS=<previous release SHA256SUMS>
#
# Safety gate: for every Cudy BL2 variant, the stock build must be byte-identical to the
# official preloader of that release, or nothing is produced.
set -eu
ver=${1:?OpenWrt version, e.g. 25.12.7}
out=${2:?output dir}
clocks=${CLOCKS:-1400 1500 1600 1700}
repo=$(cd "$(dirname "$0")/.." && pwd -P)
mirror=${OPENWRT_MIRROR:-https://downloads.openwrt.org}
base="$mirror/releases/$ver/targets/mediatek/filogic"
work=${WORK:-$(mktemp -d)}
mkdir -p "$work" "$out"
work=$(cd "$work" && pwd -P); out=$(cd "$out" && pwd -P)

log() { printf '\n=== %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
sha_of() { awk -v f="$1" '{n=$2; sub(/^\*/,"",n)} n==f {print $1}' "$work/sha256sums"; }
fetch_verified() {
	exp=$(sha_of "$1"); [ -n "$exp" ] || die "no checksum for $1 in release sha256sums"
	[ -f "$work/$1" ] || curl -fsSL "$base/$1" -o "$work/$1"
	echo "$exp  $work/$1" | sha256sum -c --quiet - || die "checksum mismatch: $1"
}
run_logged() { # logfile cmd...
	l=$1; shift
	"$@" > "$l" 2>&1 || { tail -60 "$l" >&2; return 1; }
}

log "OpenWrt $ver: release metadata"
curl -fsSL "$base/sha256sums" -o "$work/sha256sums" || die "release $ver mediatek/filogic not found"
sdk_file=$(awk '{n=$2; sub(/^\*/,"",n); print n}' "$work/sha256sums" | grep '^openwrt-sdk-.*\.tar\.zst$' | head -1)
[ -n "$sdk_file" ] || die "no SDK in release sha256sums"

log "SDK: $sdk_file"
fetch_verified "$sdk_file"
if [ ! -d "$work/sdk" ]; then
	(cd "$work" && tar --zstd -xf "$sdk_file" && mv "${sdk_file%.tar.zst}" sdk)
fi

log "OpenWrt source v$ver"
[ -d "$work/openwrt" ] || git clone -q --depth 1 -b "v$ver" https://github.com/openwrt/openwrt.git "$work/openwrt"

mk="$work/openwrt/target/linux/mediatek/image/filogic.mk"
awk '/^define Device\//{d=$2; sub(/^Device\//,"",d)}
     /ARTIFACT\/preloader\.bin[ \t]*:=[ \t]*mt7981-bl2[ \t]+cudy-/{print d, $NF}' "$mk" > "$work/devices.txt"
[ -s "$work/devices.txt" ] || die "no Cudy mt7981 preloader devices found in filogic.mk"
variants=$(awk '{print $2}' "$work/devices.txt" | sort -u)
echo "variants: $variants"

notes_variants=""
for v in $variants; do
	log "Variant $v"
	devs=$(awk -v v="$v" '$2==v {print $1}' "$work/devices.txt")
	expected=""; ref=""; listed=""
	for d in $devs; do
		f="openwrt-$ver-mediatek-filogic-$d-preloader.bin"
		h=$(sha_of "$f")
		[ -n "$h" ] || { echo "warning: no official preloader published for $d"; continue; }
		listed="$listed $d"
		if [ -z "$expected" ]; then expected=$h; ref=$f
		elif [ "$h" != "$expected" ]; then die "official $v preloaders differ between devices ($d)"; fi
	done
	[ -n "$expected" ] || die "no official preloader for variant $v"
	fetch_verified "$ref"
	echo "official stock: $expected ($ref)"

	run_logged "$work/log-$v-stock.txt" sh "$repo/bl2/build-bl2.sh" "$work/sdk" "$work/openwrt" "$v" stock "$work/bl2" ||
		die "stock $v build failed"
	got=$(sha256sum "$work/bl2/mt7981-$v-preloader-stock.bin" | cut -d' ' -f1)
	[ "$got" = "$expected" ] || die "stock $v build ($got) is NOT identical to the official preloader ($expected). Refusing to build OC images."
	echo "stock build is byte-identical: OK"
	cp "$work/bl2/mt7981-$v-preloader-stock.bin" "$out/"
	size=$(wc -c < "$out/mt7981-$v-preloader-stock.bin")

	for mhz in $clocks; do
		run_logged "$work/log-$v-$mhz.txt" sh "$repo/bl2/build-bl2.sh" "$work/sdk" "$work/openwrt" "$v" "$mhz" "$work/bl2" ||
			die "$v $mhz MHz build failed (patch no longer applies?)"
		f="$work/bl2/mt7981-$v-preloader-$mhz.bin"
		cmp -s "$f" "$out/mt7981-$v-preloader-stock.bin" && die "$v $mhz MHz build is identical to stock (patch not applied?)"
		[ "$(wc -c < "$f")" = "$size" ] || die "$v $mhz MHz build has unexpected size"
		cp "$f" "$out/"
		echo "built $mhz MHz"
	done

	changed="unknown (no previous release to compare)"
	if [ -n "${PREV_SUMS:-}" ] && [ -s "$PREV_SUMS" ]; then
		prev=$(awk -v f="mt7981-$v-preloader-stock.bin" '{n=$2; sub(/^\*/,"",n)} n==f {print $1}' "$PREV_SUMS")
		if [ -z "$prev" ]; then changed="new variant"
		elif [ "$prev" = "$expected" ]; then changed="no (same as previous release)"
		else changed="**yes**"; fi
	fi
	notes_variants="$notes_variants
### \`$v\`
- Devices:$(for d in $listed; do printf ' %s' "\`$d\`"; done)
- Official stock preloader: \`$expected\`, rebuilt byte-identical
- Stock preloader changed since previous release: $changed
"
done

log "Runtime module"
sdk_hash=$(grep -o '[0-9a-f]\{32\}' "$work/sdk/include/kernel.mk" | head -1 || true)
kdir=$(curl -fsSL "$base/kmods/" | grep -o '[0-9][0-9.]*-[0-9]*-[0-9a-f]\{32\}/' | head -1 | tr -d /)
rel_hash=${kdir##*-}
mod_status="failed"
if [ -n "$sdk_hash" ] && [ "$sdk_hash" = "$rel_hash" ] &&
   run_logged "$work/log-module.txt" sh "$repo/runtime/build-module.sh" "$work/sdk" "$work/mod"; then
	rm -rf "$work/bundle"; mkdir -p "$work/bundle/mt7981-oc"
	cp "$repo/runtime/oc.sh" "$work/mod/mt7981_oc_hold.ko" "$repo/runtime/LICENSE" "$work/bundle/mt7981-oc/"
	(cd "$work/bundle" && tar -czf "$out/mt7981-oc-runtime-$ver.tar.gz" mt7981-oc)
	mod_status="ok (kernel ${kdir})"
else
	echo "warning: runtime module not built (sdk hash '$sdk_hash', release kmods '$kdir'); continuing with preloaders" >&2
fi

(cd "$out" && sha256sum ./*.bin ./*.tar.gz 2>/dev/null | sed 's| \./| |' > SHA256SUMS)

cat > "$out/RELEASE_NOTES.md" <<NOTES
Automatically built for **OpenWrt $ver** (mediatek/filogic, ubootmod layout).

> [!WARNING]
> Auto-built and **not tested on hardware** for this release. Overclocking is at your own
> risk. A preloader that doesn't boot needs USB-UART recovery (see \`docs/recovery.md\`).
> Find a stable clock with the runtime module first, then flash the matching preloader.

Clocks: $clocks MHz. Each variant's stock build was verified byte-identical to the official
OpenWrt preloader before any overclocked image was built.
$notes_variants
### Runtime module
- \`mt7981-oc-runtime-$ver.tar.gz\`: $mod_status. Needs the stock preloader, only loads on this release's kernel.

If the stock preloader didn't change and you already run an overclocked one, there's
nothing to reflash. sysupgrade doesn't touch the preloader.

Verify downloads with \`SHA256SUMS\`.
NOTES

log "Done"
cat "$out/SHA256SUMS"

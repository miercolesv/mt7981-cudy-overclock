# Building

Both builds use the official **OpenWrt SDK** for mediatek/filogic of the same release as the
router (`openwrt-sdk-<ver>-mediatek-filogic_gcc-*_musl.Linux-x86_64.tar.zst`).

Host packages (Debian/Ubuntu): `build-essential gawk rsync zstd file python3 python3-setuptools swig kmod git`.

## Preloader (BL2)

```sh
git clone --depth 1 -b v25.12.6 https://github.com/openwrt/openwrt.git openwrt
# SDK: https://downloads.openwrt.org/releases/25.12.6/targets/mediatek/filogic/
tar --zstd -xf openwrt-sdk-25.12.6-mediatek-filogic_*.tar.zst && mv openwrt-sdk-25.12.6-* sdk

# 1. Build stock and compare with the official ...-ubootmod-preloader.bin for your device
sh bl2/build-bl2.sh sdk openwrt cudy-ddr3 stock out/
sha256sum out/mt7981-cudy-ddr3-preloader-stock.bin

# 2. Build the clock you want (multiple of 20 MHz, 1320..1800)
sh bl2/build-bl2.sh sdk openwrt cudy-ddr3 1600 out/
```

Step 1 must be byte-identical to the official file. If it isn't, your SDK/source don't
match the release, and you shouldn't flash anything built from them. The script only
builds one TF-A variant and takes a few minutes on the first run (host tools).

Which variant: look up your device in `target/linux/mediatek/image/filogic.mk`,
`ARTIFACT/preloader.bin := mt7981-bl2 <variant>`.

`gen-patch.sh <MHz>` prints the patch alone if you'd rather drop it into
`package/boot/arm-trusted-firmware-mediatek/patches/` of a full OpenWrt build.

## Runtime module

```sh
sh runtime/build-module.sh sdk out/
```

Checks vermagic against the SDK kernel and resolves every imported symbol against
`Module.symvers`. It prints the SDK's kernel hash. That must match the hash in the
router's kmods directory / kernel package for the release. Module builds aren't
bit-reproducible (the temporary build path is embedded), so your sha256 will differ from
the prebuilt one.

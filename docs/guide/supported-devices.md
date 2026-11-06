# Supported devices

Prebuilt files are for **OpenWrt 25.12.6**. The official 25.12.6 preloader is
byte-identical across each group below, so one set of files covers the whole
group.

| BL2 variant | Devices (`*-ubootmod` images only) | Tested |
|---|---|---|
| `cudy-ddr3` | WR3000H v1, WR3000S v1, WR3000E v1, TR3000 v1, M3000 v1/v2, M3000 v2 YT8821, WBR3000UAX v1 | WR3000H v1 (BL2 1500, module 1500 and 1600) |
| `cudy-ddr4` | WR3000P v1 | **not tested on hardware** |

## Official stock preloader hashes

Compare your router's current preloader with these before flashing (see
[Flashing the preloader](/bl2-flashing#_1-identify-and-back-up-your-current-preloader)).

| Variant | sha256 of the first 230232 bytes of BL2 (25.12.6) |
|---|---|
| `cudy-ddr3` | `524f588dabb7c23dcecf148e793721ad4e451041acf124694486312e86ada472` |
| `cudy-ddr4` | `9be2b11ca74912f29ef984e33b8ced740a9bdb02411ba9dcb9b464bcf53e5442` |

## Not supported

- The stock Cudy firmware layout (non-ubootmod images).
- Other brands. The preloaders are built for the Cudy TF-A variants.

The runtime module works on any MT7981 board whose clock registers read the
expected stock values. It checks this first and refuses otherwise.

## Finding your variant

Every device's preloader is defined in OpenWrt's
`target/linux/mediatek/image/filogic.mk`:

```make
ARTIFACT/preloader.bin := mt7981-bl2 <variant>
```

New Cudy devices that use a `cudy-*` variant are picked up by the
[automated builds](/automation).

## Other OpenWrt versions

The prebuilt preloader doesn't depend on the kernel, but rebuild it for your
release anyway so it matches the U-Boot (FIP) you have. The prebuilt module only
loads on kernel 6.12.112 (25.12.6). Newer releases get their own `oc-<version>`
release automatically; otherwise see [Building](/building).

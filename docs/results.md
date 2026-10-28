# Results

One unit, so not representative of every chip. Ambient temperature not recorded.

**Cudy WR3000H v1, OpenWrt 25.12.6 (ubootmod), stock cooling**

coremark (single thread, `apk add coremark`):

| Configuration | Iterations/s | vs stock |
|---|---|---|
| Stock 1300 MHz | 4355 | — |
| Runtime module 1500 MHz | 5011 | +15.1 % |
| BL2 v2 1500 MHz | 5074 | +16.5 % |
| Runtime module 1600 MHz | 5430 | +24.7 % |
| BL2 v1 "1500" (POSDIV bug, actually 750 MHz) | 2539 | −41.7 % |

Clock ratios for comparison: 1500/1300 = +15.4 %, 1600/1300 = +23.1 %.

CPU temperature (`thermal_zone0`):

| Condition | Temperature |
|---|---|
| Idle | 64–65.5 °C |
| 1500 MHz, both cores coremark + speed test | peak 68.4 °C |
| 1600 MHz, both cores coremark, sustained | levelled at ~70.3 °C |

Most of the idle heat comes from the Wi-Fi radios; the CPU overclock added only a few
degrees under full load. 1600 MHz was chosen as the permanent setting.

Please add your device, clock, coremark and temperatures via an issue or PR.

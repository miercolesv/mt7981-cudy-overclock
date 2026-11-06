---
layout: home

hero:
  name: MT7981 overclock
  text: More speed for Cudy routers
  tagline: Overclock the MediaTek MT7981B (Filogic 820) in Cudy routers running OpenWrt ubootmod, from the stock 1.3 GHz up to 1.4–1.7 GHz. Test safely in RAM first, then make it permanent.
  image:
    src: /logo.svg
    alt: MT7981 overclock
  actions:
    - theme: brand
      text: Get started
      link: /guide/getting-started
    - theme: alt
      text: Supported devices
      link: /guide/supported-devices
    - theme: alt
      text: Results
      link: /results

features:
  - icon: 🧪
    title: Test without risk
    details: The runtime module changes the clock while the router runs. Nothing is written to flash, a 74 °C guard drops back to stock, and a reboot undoes everything.
    link: /runtime-module
  - icon: 📌
    title: Make it permanent
    details: The official OpenWrt preloader, rebuilt with only the CPU PLL setting changed. Survives reboots, factory resets and sysupgrades.
    link: /bl2-flashing
  - icon: 📈
    title: Real gains
    details: On a WR3000H v1, coremark went from 4355 to 5074 at 1.5 GHz (+16.5 %) and 5430 at 1.6 GHz (+24.7 %).
    link: /results
  - icon: ✅
    title: Verified builds
    details: The stock preloader must rebuild byte-identical to OpenWrt's official file before any overclocked one is published.
    link: /automation
  - icon: 🔁
    title: Follows OpenWrt releases
    details: A daily workflow builds and publishes new preloaders when a new stable OpenWrt release appears.
    link: /automation
  - icon: 🛟
    title: A way back
    details: Every step is reversible, and a preloader that doesn't boot can be recovered over a serial cable.
    link: /recovery
---

::: danger Overclocking is at your own risk
It runs the chip outside its specification. The CPU voltage can't be changed,
which limits headroom. A preloader that hangs leaves the router unable to boot
until it's recovered with a 3.3 V USB-UART adapter. **Always test with the runtime
module first.**
:::

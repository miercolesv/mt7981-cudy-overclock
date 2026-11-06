# How it works

## The CPU clock on the MT7981

The MT7981 has no DVFS/cpufreq in OpenWrt. The preloader (BL2) programs the CPU
PLL (ARMPLL) once at boot:

```
f_cpu = 40 MHz × PCW / 2^POSDIV        stock: PCW = 0x82 (130), POSDIV = 1 → 1300 MHz
                                       OC:    PCW = MHz/20,     POSDIV = 0
```

## The preloader patch

The patch changes two lines in TF-A's
`plat/mediatek/mt7981/drivers/pll/pll.c`:

```c
mmio_write_32(ARMPLL_CON1, 0x50000000);            /* 1600 MHz, PCW = 0x50 */
mmio_clrsetbits_32(ARMPLL_CON0, 0x70, 0x104);      /* POSDIV field cleared → /1 */
```

::: warning The POSDIV field must be cleared
Its reset value is /2, so OR-ing in `0x104` alone gives **half** the intended
clock. That was the v1 bug (see [Known issues](/guide/known-issues#v1-preloaders-run-at-half-speed)).
:::

Everything else is the stock OpenWrt build: an unpatched build with
`bl2/build-bl2.sh` is byte-identical to the official preloader for both
variants. Patches for any multiple of 20 MHz between 1320 and 1800 come from
`bl2/gen-patch.sh`.

## The runtime module

The module (`mt7981_oc_hold.ko`, controlled by `oc.sh`) does the same thing
while the router runs:

1. Loads read-only and checks the clock registers: CPU mux `000e0201`, CCI
   divider `00000012`, ARMPLL_CON0 `00670111`, ARMPLL_CON1 `82000000`. Any
   mismatch → abort, no writes.
2. Refuses if the CPU is at 70 °C or more, or less than 32 MiB of RAM is free.
3. With the other core halted, switches the CPU to its alternate clock,
   reprograms ARMPLL (POSDIV /1, PCW = MHz·2²⁵/40), waits for lock, verifies all
   readbacks and switches back. On failure it restores stock; if that fails, it
   reboots.
4. Every second, checks the registers and the temperature. At 74 °C, on a read
   error or a mismatch, it goes back to 1300 MHz.

It writes only three registers:

| Register | Address |
|---|---|
| BUS_PLL_DIVIDER | `0x104007c0` |
| ARMPLL_CON0 | `0x1001e200` |
| ARMPLL_CON1 | `0x1001e204` |

## Why there's no voltage change

There is no vcore control on these boards, so the CPU runs at its stock
voltage. That's what limits the headroom, and why each unit's limit differs.

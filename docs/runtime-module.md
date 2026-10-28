# Runtime module (`mt7981_oc_hold.ko` + `oc.sh`)

Changes the CPU clock while the router is running. Nothing is written to flash. A reboot,
`oc.sh 1300`, the timer or the guard puts it back to 1300 MHz.

Source: Dystopian/openwrt-mt7981-overclock (fork of rison1337/wr3000s-openwrt-overclock),
included unmodified in `runtime/source/`. Upstream notes the custom-frequency build hasn't
been validated on hardware; on a WR3000H v1 it worked at 1500 and 1600 MHz
([results.md](results.md)).

## Requirements

* Stock preloader (1300 MHz). With an overclocked BL2 the registers aren't at stock values
  and the module refuses (no writes).
* Module built for your exact kernel. The prebuilt one is for OpenWrt 25.12.6
  (kernel 6.12.112, kernel hash `f0a7348f9cb959e1bf4d0447669b031e`).
* `jsonfilter`, `apk` (default in 25.12).

## Usage

```sh
scp -O -r runtime root@192.168.1.1:/root/mt7981-oc
cd /root/mt7981-oc && cp prebuilt/25.12.6/mt7981_oc_hold.ko .
sh ./oc.sh check                  # platform checks only
sh ./oc.sh 1500 120               # MHz, optional timer 30..1800 s
sh ./oc.sh 1600                   # no timer: until 1300 / reboot / guard
sh ./oc.sh status
sh ./oc.sh 1300                   # return to stock, verify, unload
```

* MHz: integer 1301–2000; above 1700 requires `--risk`.
* `/tmp` is cleared on reboot; keeping the folder in `/root` saves re-uploading.
* **Never autostart it.** A freeze at boot becomes a boot loop.

## What it does

1. Loads read-only and checks: CPU mux `000e0201`, CCI divider `00000012`,
   ARMPLL_CON0 `00670111`, ARMPLL_CON1 `82000000`. Any mismatch → abort, no writes.
2. Refuses if CPU temperature ≥ 70 °C or less than 32 MiB RAM free.
3. In `stop_machine` on CPU0 (other core halted): switches the CPU to its alternate
   clock, reprograms ARMPLL (POSDIV /1, PCW = MHz·2²⁵/40), waits for lock, verifies all
   readbacks, switches back. On failure: restore stock; if that fails, emergency reboot.
4. Every second: checks registers and temperature. ≥ 74 °C, read error or mismatch →
   back to 1300.

Writes only BUS_PLL_DIVIDER `0x104007c0`, ARMPLL_CON0 `0x1001e200`, ARMPLL_CON1 `0x1001e204`.

## Stability testing

```sh
apk add coremark
sh ./oc.sh 1600
for i in 1 2; do (while :; do coremark >/dev/null; done) & done
while :; do sh ./oc.sh status | grep -o '"active":[a-z]*\|"reason":"[^"]*"\|"temp_peak_mc":[0-9]*' | tr '\n' ' '; echo; sleep 10; done
# Ctrl+C, then: kill %1 %2
```

(BusyBox has no `watch`.) Add heavy Wi-Fi traffic at the same time, e.g. iperf3 between a
wireless client and a wired host through the router. Wi-Fi load is where marginal clocks
tend to fail. Run for an hour or more and go up 100 MHz at a time.

| Result | Meaning |
|---|---|
| `active:true`, no freezes | that clock is a candidate for the preloader |
| `reason: temperature-limit` | cooling is the limit, not the chip; improve airflow or stay lower |
| freeze | pull power; it boots at stock. Use the previous step |

Confirm the clock is real with coremark: the score should scale with MHz/1300.

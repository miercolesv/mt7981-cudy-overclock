/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef MT7981_OC_FREQ_H
#define MT7981_OC_FREQ_H

#ifdef __KERNEL__
#include <linux/types.h>
#else
#include <stdbool.h>
#include <stdint.h>
typedef uint32_t u32;
typedef uint64_t u64;
#endif

/* Input limits, NOT a hardware safety/stability specification. */
#define OC_MIN_MHZ 1300U
#define OC_MAX_MHZ 2000U
#define OC_RISK_MHZ 1700U
#define OC_XTAL_HZ 40000000ULL
#define OC_PCW_FRAC_BITS 25U

static inline bool mt7981_oc_request_allowed(unsigned int mhz, bool allow_unsafe)
{
	if (mhz < OC_MIN_MHZ || mhz > OC_MAX_MHZ)
		return false;
	return mhz <= OC_RISK_MHZ || allow_unsafe;
}

/* POSDIV=0 target path only. 1300 uses the separate read-only stock branch.
 * Round PCW to nearest: error <= 40 MHz / 2^26, less than 0.6 Hz.
 * No MMIO, clocks, allocation or hardware access in these helpers. */
static inline bool mt7981_oc_calc_pcw(unsigned int mhz, u32 *pcw)
{
	u64 value;

	if (!pcw || mhz <= OC_MIN_MHZ || mhz > OC_MAX_MHZ)
		return false;
	value = ((u64)mhz << OC_PCW_FRAC_BITS) + 20;
	*pcw = (u32)(value / 40);
	return true;
}

static inline u64 mt7981_oc_rate_hz(u32 pcw, u32 con0)
{
	unsigned int shift = OC_PCW_FRAC_BITS + ((con0 >> 4) & 7);
	u64 divisor = 1ULL << shift;

	return ((u64)pcw * OC_XTAL_HZ + divisor / 2) / divisor;
}

static inline u64 mt7981_oc_rate_mhz(u32 pcw, u32 con0)
{
	return (mt7981_oc_rate_hz(pcw, con0) + 500000) / 1000000;
}

#endif

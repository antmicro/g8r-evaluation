// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

// so every saturating top keeps one return type.
fn sat_s16(x: s32) -> s32 {
  let hi = s32:32767;
  let lo = s32:0 - s32:32768;
  if x > hi {
    hi
  } else {
    if x < lo {
      lo
    } else {
      x
    }
  }
}

// Clamp an s24 accumulator into signed 16-bit range.
fn sat_s16_in24(y: s24) -> s24 {
  let hi = s24:32767;
  let lo = s24:0 - s24:32768;
  if y > hi {
    hi
  } else {
    if y < lo {
      lo
    } else {
      y
    }
  }
}

// Two's-complement magnitude without a branch.
fn abs32(x: s32) -> s32 {
  let m = x >> u32:31;
  (x ^ m) - m
}

// 4-input balanced adder group.
fn tree4(v: s16[4]) -> s16 {
  (v[0] + v[1]) + (v[2] + v[3])
}

// 8-input balanced adder tree: 3 levels instead of a 7-adder chain.
fn tree8(v: s16[8]) -> s16 {
  tree4([v[0], v[1], v[2], v[3]]) + tree4([v[4], v[5], v[6], v[7]])
}

// Clamp one s16 sample into signed 12-bit range.
fn clamp12(v: s16) -> s16 {
  let hi = s16:2047;
  let lo = s16:0 - s16:2048;
  if v > hi {
    hi
  } else {
    if v < lo {
      lo
    } else {
      v
    }
  }
}

// ---- 00: BASE ----
// 8-tap direct-form FIR: s16 samples x s16 runtime coefficients, each
// product added into one 32-bit accumulator through a serial carry
// chain, arithmetic >> 15, saturate to s16, return s32.
pub fn fir_00_base8(x: s16[8], h: s16[8]) -> s32 {
  let acc = for (i, acc): (u32, s32) in u32:0..u32:8 {
    acc + ((x[i] as s32) * (h[i] as s32))
  }(s32:0);
  sat_s16(acc >> u32:15)
}

// ---- 01: tap count 8 -> 6 ----
// Delta vs 00: two taps removed; two multipliers and two 32-bit adders
// of the chain disappear.
pub fn fir_01_taps6(x: s16[6], h: s16[6]) -> s32 {
  let acc = for (i, acc): (u32, s32) in u32:0..u32:6 {
    acc + ((x[i] as s32) * (h[i] as s32))
  }(s32:0);
  sat_s16(acc >> u32:15)
}

// ---- 02: accumulator 32 -> 24 bits ----
// Delta vs 01: products are formed in and summed into a 24-bit
// accumulator, so the multiplier arrays and every adder shrink by 8
// bits; the output type becomes s24.
pub fn fir_02_acc24(x: s16[6], h: s16[6]) -> s24 {
  let acc = for (i, acc): (u32, s24) in u32:0..u32:6 {
    acc + ((x[i] as s24) * (h[i] as s24))
  }(s24:0);
  sat_s16_in24(acc >> u32:15)
}

// ---- 03: tap count 6 -> 10 ----
// Delta vs 02: four more taps on the same 24-bit datapath.
pub fn fir_03_taps10(x: s16[10], h: s16[10]) -> s24 {
  let acc = for (i, acc): (u32, s24) in u32:0..u32:10 {
    acc + ((x[i] as s24) * (h[i] as s24))
  }(s24:0);
  sat_s16_in24(acc >> u32:15)
}

// ---- 04: coefficients become compile-time constants ----
// Delta vs 03: `h` stops being an input; the 10 coefficients come from a
// const table, so each multiplier constant-folds into a sparse sum of
// shifted samples. The zero coefficient at index 5 removes that tap's
// adder entirely.
const H10: s16[10] = [
  s16:128, s16:-97, s16:41, s16:203, s16:-61,
  s16:0, s16:173, s16:-34, s16:88, s16:-12,
];

pub fn fir_04_const_h(x: s16[10]) -> s24 {
  let acc = for (i, acc): (u32, s24) in u32:0..u32:10 {
    acc + ((x[i] as s24) * (H10[i] as s24))
  }(s24:0);
  sat_s16_in24(acc >> u32:15)
}

// ---- 05: constant coefficients become powers of two ----
// Delta vs 04: the const table is replaced by signed powers of two, so
// every constant multiply collapses into a shift and the multiplier
// arrays vanish entirely.
const H10_POW2: s16[10] = [
  s16:1, s16:-2, s16:4, s16:-8, s16:16,
  s16:-32, s16:64, s16:-64, s16:128, s16:-256,
];

pub fn fir_05_pow2_h(x: s16[10]) -> s24 {
  let acc = for (i, acc): (u32, s24) in u32:0..u32:10 {
    acc + ((x[i] as s24) * (H10_POW2[i] as s24))
  }(s24:0);
  sat_s16_in24(acc >> u32:15)
}

// ---- 06: sample/coefficient width 16 -> 12 ----
// Delta vs 05: back to runtime coefficients, but the front end is
// 12-bit, so each multiplier loses most of its partial-product array.
pub fn fir_06_w12(x: s12[10], h: s12[10]) -> s32 {
  let acc = for (i, acc): (u32, s32) in u32:0..u32:10 {
    acc + ((x[i] as s32) * (h[i] as s32))
  }(s32:0);
  sat_s16(acc >> u32:15)
}

// ---- 07: sample and coefficient width 12 -> 8 ----
// Delta vs 06: 8-bit samples and Q8 coefficients summed in a 16-bit
// accumulator; the >> 15 scale becomes >> 7.
pub fn fir_07_w8(x: s8[10], h: s8[10]) -> s16 {
  let acc = for (i, acc): (u32, s16) in u32:0..u32:10 {
    acc + ((x[i] as s16) * (h[i] as s16))
  }(s16:0);
  acc >> u32:7
}

// ---- 08: serial accumulator -> balanced adder tree ----
// Delta vs 07: 8 taps whose products are summed by a 3-level balanced
// tree (`map` + `tree8`) instead of one long carry chain.
pub fn fir_08_tree8(x: s8[8], h: s8[8]) -> s16 {
  let prods = map(u32:0..u32:8, |i| (x[i] as s16) * (h[i] as s16));
  tree8(prods) >> u32:7
}

// ---- 09: single accumulator -> even/odd split accumulators ----
// Delta vs 08: two independent 17-bit accumulators (even taps, odd taps)
// that meet in exactly one final adder, halving the carry-chain depth.
pub fn fir_09_split_acc(x: s8[8], h: s8[8]) -> s17 {
  let even = for (i, acc): (u32, s17) in u32:0..u32:4 {
    let j = i * u32:2;
    acc + ((x[j] as s17) * (h[j] as s17))
  }(s17:0);
  let odd = for (i, acc): (u32, s17) in u32:0..u32:4 {
    let j = i * u32:2 + u32:1;
    acc + ((x[j] as s17) * (h[j] as s17))
  }(s17:0);
  (even + odd) >> u32:7
}

// ---- 10: truncating shift -> round-to-nearest, saturation added ----
// Delta vs 09: half an output LSB is added before the bits are dropped,
// turning the plain shift into an incrementer plus a shift, and the
// result is clamped into s16 range so the clamps come back.
pub fn fir_10_round_sat(x: s8[8], h: s8[8]) -> s17 {
  let even = for (i, acc): (u32, s17) in u32:0..u32:4 {
    let j = i * u32:2;
    acc + ((x[j] as s17) * (h[j] as s17))
  }(s17:0);
  let odd = for (i, acc): (u32, s17) in u32:0..u32:4 {
    let j = i * u32:2 + u32:1;
    acc + ((x[j] as s17) * (h[j] as s17))
  }(s17:0);
  let sum = even + odd + (s17:1 << u32:6);
  let y = sum >> u32:7;
  let hi = s17:511;
  let lo = s17:0 - s17:512;
  if y > hi {
    hi
  } else {
    if y < lo {
      lo
    } else {
      y
    }
  }
}

// ---- 11: output becomes (sample, overflow) ----
// Delta vs 10: the rounded sum is truncated to s16 and a sticky overflow
// flag is reported alongside it, so the top returns a tuple instead of a
// clamped value.
pub fn fir_11_out_flags(x: s8[8], h: s8[8]) -> (s16, bool) {
  let even = for (i, acc): (u32, s17) in u32:0..u32:4 {
    let j = i * u32:2;
    acc + ((x[j] as s17) * (h[j] as s17))
  }(s17:0);
  let odd = for (i, acc): (u32, s17) in u32:0..u32:4 {
    let j = i * u32:2 + u32:1;
    acc + ((x[j] as s17) * (h[j] as s17))
  }(s17:0);
  let sum = even + odd + (s17:1 << u32:6);
  let over = (sum > s17:32767) | (sum < (s17:0 - s17:32768));
  let y = sum >> u32:7;
  ((y as u17)[0:16] as s16, over)
}

// ---- 12: magnitude output ----
// Delta vs 11: the full rounded sum goes through a two's-complement
// absolute value before truncation, adding a conditional negate (xor +
// increment) across the accumulator width.
pub fn fir_12_abs_out(x: s8[8], h: s8[8]) -> (s16, bool) {
  let even = for (i, acc): (u32, s17) in u32:0..u32:4 {
    let j = i * u32:2;
    acc + ((x[j] as s17) * (h[j] as s17))
  }(s17:0);
  let odd = for (i, acc): (u32, s17) in u32:0..u32:4 {
    let j = i * u32:2 + u32:1;
    acc + ((x[j] as s17) * (h[j] as s17))
  }(s17:0);
  let sum = even + odd + (s17:1 << u32:6);
  let over = (sum > s17:32767) | (sum < (s17:0 - s17:32768));
  let mag = abs32(sum as s32) >> u32:7;
  (((mag as u32)[0:16] as s16), over)
}

// ---- 13: input guard clamps every sample ----
// Delta vs 12: back to the plain saturating s32 output, but each sample
// is clamped into s12 before it reaches the multiplier, adding a compare
// plus clamp mux per tap ahead of the multiply.
pub fn fir_13_in_guard(x: s16[8], h: s16[8]) -> s32 {
  let acc = for (i, acc): (u32, s32) in u32:0..u32:8 {
    let g = clamp12(x[i]);
    acc + ((g as s32) * (h[i] as s32))
  }(s32:0);
  sat_s16(acc >> u32:15)
}

// ---- 14: rounding added on the guarded path ----
// Delta vs 13: the guarded 8-tap path gets round-to-nearest (half an LSB
// added before the drop) instead of plain truncation.
pub fn fir_14_guard_round(x: s16[8], h: s16[8]) -> s32 {
  let acc = for (i, acc): (u32, s32) in u32:0..u32:8 {
    let g = clamp12(x[i]);
    acc + ((g as s32) * (h[i] as s32))
  }(s32:0);
  sat_s16((acc + (s32:1 << u32:14)) >> u32:15)
}

// ---- 15: symmetric folding, 12 taps ----
// Delta vs 14: the response is symmetric (h[i] == h[11-i]), so samples
// are summed pairwise and only 6 multipliers are needed: fewer
// multipliers, more pre-adders, and the input guard is dropped.
pub fn fir_15_sym12(x: s16[12], h: s16[12]) -> s32 {
  let acc = for (i, acc): (u32, s32) in u32:0..u32:6 {
    let m = u32:11 - i;
    let pair = (x[i] as s32) + (x[m] as s32);
    acc + (pair * (h[i] as s32))
  }(s32:0);
  sat_s16(acc >> u32:15)
}

// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

import std;
import float32;
import bfloat16;

// --- arithmetic (carry chains) ---
pub fn arith_add8(a: u8, b: u8) -> u8 { a + b }
pub fn arith_add16(a: u16, b: u16) -> u16 { a + b }
pub fn arith_add32(a: u32, b: u32) -> u32 { a + b }
pub fn arith_add64(a: u64, b: u64) -> u64 { a + b }
pub fn arith_sub32(a: u32, b: u32) -> u32 { a - b }
pub fn arith_mul8(a: u8, b: u8) -> u16 { std::umul(a, b) }
pub fn arith_mul16(a: u16, b: u16) -> u32 { std::umul(a, b) }
pub fn arith_mul24(a: u24, b: u24) -> u48 { std::umul(a, b) }
pub fn arith_smul16(a: s16, b: s16) -> s32 { std::smul(a, b) }
pub fn arith_div8(a: u8, b: u8) -> u8 { if b == u8:0 { u8:0 } else { a / b } }
pub fn arith_mac16(a: u16, b: u16, c: u32) -> u32 { std::umul(a, b) + c }
pub fn arith_sum4x16(a: u16, b: u16, c: u16, d: u16) -> u18 {
    (a as u18) + (b as u18) + (c as u18) + (d as u18)
}

// --- xor-heavy ---
pub fn xor_parity64(x: u64) -> u1 { xor_reduce(x) }
pub fn xor_crc32_byte(crc: u32, data: u8) -> u32 {
    const POLY = u32:0xEDB88320;
    let crc = crc ^ (data as u32);
    for (_, c): (u32, u32) in u32:0..u32:8 {
        let mask = -(c & u32:1);
        (c >> 1) ^ (POLY & mask)
    }(crc)
}
pub fn xor_popcount32(x: u32) -> u6 { std::popcount(x) as u6 }
pub fn xor_popcount64(x: u64) -> u7 { std::popcount(x) as u7 }
pub fn xor_gray32(x: u32) -> u32 {
    for (i, g): (u32, u32) in u32:0..u32:5 { g ^ (g >> (u32:1 << i)) }(x)
}
pub fn xor_eq64(a: u64, b: u64) -> u1 { a == b }
pub fn xor_ult32(a: u32, b: u32) -> u1 { a < b }
pub fn xor_ult64(a: u64, b: u64) -> u1 { a < b }

// --- mux / shift heavy ---
pub fn mux_shll32(x: u32, s: u5) -> u32 { x << s }
pub fn mux_shra64(x: s64, s: u6) -> s64 { x >> s }
pub fn mux_rotl32(x: u32, s: u5) -> u32 { std::rotl(x, s as u32) }
pub fn mux_sel8x32(s: u3, a: u32[8]) -> u32 { a[s] }
pub fn mux_sel16x16(s: u4, a: u16[16]) -> u16 { a[s] }
pub fn mux_update8x16(a: u16[8], i: u3, v: u16) -> u16[8] { update(a, i, v) }

// --- control / encoder ---
pub fn ctrl_clz32(x: u32) -> u6 { clz(x) as u6 }
pub fn ctrl_prio_enc32(x: u32) -> u5 { encode(one_hot(x, true) as u32) }
pub fn ctrl_decode5(x: u5) -> u32 { decode<u32>(x) }
pub fn ctrl_max4x16(a: u16, b: u16, c: u16, d: u16) -> u16 {
    let m0 = if a > b { a } else { b };
    let m1 = if c > d { c } else { d };
    if m0 > m1 { m0 } else { m1 }
}
pub fn ctrl_sat_add16(a: u16, b: u16) -> u16 {
    let (c, s) = std::uadd_with_overflow<u32:16>(a, b);
    if c { u16:0xffff } else { s }
}

// --- floating point (mixed) ---
pub fn fp_f32_add(a: float32::F32, b: float32::F32) -> float32::F32 { float32::add(a, b) }
pub fn fp_f32_mul(a: float32::F32, b: float32::F32) -> float32::F32 { float32::mul(a, b) }
pub fn fp_bf16_mul(a: bfloat16::BF16, b: bfloat16::BF16) -> bfloat16::BF16 {
    bfloat16::mul(a, b)
}
pub fn fp_bf16_add(a: bfloat16::BF16, b: bfloat16::BF16) -> bfloat16::BF16 {
    bfloat16::add(a, b)
}

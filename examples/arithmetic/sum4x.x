// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

pub fn arith_sum4x8(a: u8, b: u8, c: u8, d: u8) -> u10 {
    (a as u10) + (b as u10) + (c as u10) + (d as u10)
}
pub fn arith_sum4x16(a: u16, b: u16, c: u16, d: u16) -> u18 {
    (a as u18) + (b as u18) + (c as u18) + (d as u18)
}
pub fn arith_sum4x32(a: u32, b: u32, c: u32, d: u32) -> u34 {
    (a as u34) + (b as u34) + (c as u34) + (d as u34)
}
pub fn arith_sum4x64(a: u64, b: u64, c: u64, d: u64) -> bits[66] {
    (a as bits[66]) + (b as bits[66]) + (c as bits[66]) + (d as bits[66])
}
pub fn arith_sum4x128(a: bits[128], b: bits[128], c: bits[128], d: bits[128]) -> bits[130] {
    (a as bits[130]) + (b as bits[130]) + (c as bits[130]) + (d as bits[130])
}
pub fn arith_sum4x256(a: bits[256], b: bits[256], c: bits[256], d: bits[256]) -> bits[258] {
    (a as bits[258]) + (b as bits[258]) + (c as bits[258]) + (d as bits[258])
}
pub fn arith_sum4x512(a: bits[512], b: bits[512], c: bits[512], d: bits[512]) -> bits[514] {
    (a as bits[514]) + (b as bits[514]) + (c as bits[514]) + (d as bits[514])
}

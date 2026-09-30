// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

pub fn arith_sub8(a: u8, b: u8) -> u8 { a - b }
pub fn arith_sub16(a: u16, b: u16) -> u16 { a - b }
pub fn arith_sub32(a: u32, b: u32) -> u32 { a - b }
pub fn arith_sub64(a: u64, b: u64) -> u64 { a - b }
pub fn arith_sub128(a: bits[128], b: bits[128]) -> bits[128] { a - b }
pub fn arith_sub256(a: bits[256], b: bits[256]) -> bits[256] { a - b }
pub fn arith_sub512(a: bits[512], b: bits[512]) -> bits[512] { a - b }

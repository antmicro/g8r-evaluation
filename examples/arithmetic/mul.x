// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

pub fn arith_mul8(a: u8, b: u8) -> u16 { a as u16 * b as u16 }
pub fn arith_mul16(a: u16, b: u16) -> u32 { a as u32 * b as u32 }
pub fn arith_mul32(a: u32, b: u32) -> u64 { a as u64 * b as u64 }
pub fn arith_mul48(a: u48, b: u48) -> u48 { a as u48 * b as u48 }
pub fn arith_mul64(a: u64, b: u64) -> bits[128] { a as bits[128] * b as bits[128] }

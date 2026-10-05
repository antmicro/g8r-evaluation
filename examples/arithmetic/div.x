// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

pub fn arith_div8(a: u8, b: u8) -> u8 { if b == u8:0 { u8:0 } else { a / b } }
pub fn arith_div16(a: u16, b: u16) -> u16 { if b == u16:0 { u16:0 } else { a / b } }
pub fn arith_div32(a: u32, b: u32) -> u32 { if b == u32:0 { u32:0 } else { a / b } }
pub fn arith_div48(a: u48, b: u48) -> u48 { if b == u48:0 { u48:0 } else { a / b } }
pub fn arith_div64(a: u64, b: u64) -> u64 { if b == u64:0 { u64:0 } else { a / b } }

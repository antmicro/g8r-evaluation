// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

import std;

pub fn arith_mac8(a: u8, b: u8, c: u8) -> u16 { std::umul(a, b) + c as u16 }
pub fn arith_mac16(a: u16, b: u16, c: u16) -> u32 { std::umul(a, b) + c as u32 }
pub fn arith_mac32(a: u32, b: u32, c: u32) -> u64 { std::umul(a, b) + c as u64 }
pub fn arith_mac48(a: u48, b: u48, c: u48) -> bits[96] { std::umul(a, b) + c as bits[96] }
pub fn arith_mac64(a: u64, b: u64, c: u64) -> bits[128] { std::umul(a, b) + c as bits[128]}

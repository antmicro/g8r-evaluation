// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

import std;

pub fn xor_popcount8(x: u8) -> u4 { std::popcount(x) as u4 }
pub fn xor_popcount16(x: u16) -> u5 { std::popcount(x) as u5 }
pub fn xor_popcount32(x: u32) -> u6 { std::popcount(x) as u6 }
pub fn xor_popcount64(x: u64) -> u7 { std::popcount(x) as u7 }
pub fn xor_popcount128(x: bits[128]) -> u8 { std::popcount(x) as u8 }
pub fn xor_popcount256(x: bits[256]) -> u9 { std::popcount(x) as u9 }
pub fn xor_popcount512(x: bits[512]) -> u10 { std::popcount(x) as u10 }

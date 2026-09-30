// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

import std;

pub fn rotl8(x: u8, s: u3) -> u8 { std::rotl(x, s as u8) }
pub fn rotl16(x: u16, s: u4) -> u16 { std::rotl(x, s as u16) }
pub fn rotl32(x: u32, s: u5) -> u32 { std::rotl(x, s as u32) }
pub fn rotl64(x: u64, s: u6) -> u64 { std::rotl(x, s as u64) }
pub fn rotl128(x: bits[128], s: u6) -> bits[128] { std::rotl(x, s as bits[128]) }
pub fn rotl256(x: bits[256], s: u6) -> bits[256] { std::rotl(x, s as bits[256]) }
pub fn rotl512(x: bits[512], s: u6) -> bits[512] { std::rotl(x, s as bits[512]) }

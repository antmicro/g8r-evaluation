// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

pub fn sel16x8(s: u4, a: u8[16]) -> u8 { a[s] }
pub fn sel16x16(s: u4, a: u16[16]) -> u16 { a[s] }
pub fn sel16x32(s: u4, a: u32[16]) -> u32 { a[s] }
pub fn sel16x64(s: u4, a: u64[16]) -> u64 { a[s] }
pub fn sel16x128(s: u4, a: bits[128][16]) -> bits[128] { a[s] }
pub fn sel16x256(s: u4, a: bits[256][16]) -> bits[256] { a[s] }
pub fn sel16x512(s: u4, a: bits[512][16]) -> bits[512] { a[s] }

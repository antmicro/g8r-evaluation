// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

pub fn sel8x8(s: u3, a: u8[8]) -> u8 { a[s] }
pub fn sel8x16(s: u3, a: u16[8]) -> u16 { a[s] }
pub fn sel8x32(s: u3, a: u32[8]) -> u32 { a[s] }
pub fn sel8x64(s: u3, a: u64[8]) -> u64 { a[s] }
pub fn sel8x128(s: u3, a: bits[128][8]) -> bits[128] { a[s] }
pub fn sel8x256(s: u3, a: bits[256][8]) -> bits[256] { a[s] }
pub fn sel8x512(s: u3, a: bits[512][8]) -> bits[512] { a[s] }

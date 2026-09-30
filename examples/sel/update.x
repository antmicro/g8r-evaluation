// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

pub fn update8x8(a: u8[8], i: u3, v: u8) -> u8[8] { update(a, i, v) }
pub fn update8x16(a: u16[8], i: u3, v: u16) -> u16[8] { update(a, i, v) }
pub fn update8x32(a: u32[8], i: u3, v: u32) -> u32[8] { update(a, i, v) }
pub fn update8x64(a: u64[8], i: u3, v: u64) -> u64[8] { update(a, i, v) }
pub fn update8x128(a: bits[128][8], i: u3, v: bits[128]) -> bits[128][8] { update(a, i, v) }
pub fn update8x256(a: bits[256][8], i: u3, v: bits[256]) -> bits[256][8] { update(a, i, v) }
pub fn update8x512(a: bits[512][8], i: u3, v: bits[512]) -> bits[512][8] { update(a, i, v) }

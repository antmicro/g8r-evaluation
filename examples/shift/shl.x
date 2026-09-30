// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

pub fn shll8(x: u8, s: u3) -> u8 { x << s }
pub fn shll16(x: u16, s: u4) -> u16 { x << s }
pub fn shll32(x: u32, s: u5) -> u32 { x << s }
pub fn shll64(x: u64, s: u6) -> u64 { x << s }
pub fn shll128(x: bits[128], s: u7) -> bits[128] { x << s }
pub fn shll256(x: bits[256], s: u8) -> bits[256] { x << s }
pub fn shll512(x: bits[512], s: u9) -> bits[512] { x << s }

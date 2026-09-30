// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

pub fn logic_xnor8(a: u8, b:u8) -> u8 { !(a ^ b) }
pub fn logic_xnor16(a: u16, b:u16) -> u16 { !(a ^ b) }
pub fn logic_xnor32(a: u32, b:u32) -> u32 { !(a ^ b) }
pub fn logic_xnor64(a: u64, b:u64) -> u64 { !(a ^ b) }

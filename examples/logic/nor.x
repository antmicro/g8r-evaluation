// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

pub fn logic_nor8(a: u8, b:u8) -> u8 { !(a | b) }
pub fn logic_nor16(a: u16, b:u16) -> u16 { !(a | b) }
pub fn logic_nor32(a: u32, b:u32) -> u32 { !(a | b) }
pub fn logic_nor64(a: u64, b:u64) -> u64 { !(a | b) }

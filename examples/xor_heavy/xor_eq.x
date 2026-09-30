// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

pub fn xor_eq8(a: u8, b: u8) -> u1 { a == b }
pub fn xor_eq16(a: u16, b: u16) -> u1 { a == b }
pub fn xor_eq32(a: u32, b: u32) -> u1 { a == b }
pub fn xor_eq64(a: u64, b: u64) -> u1 { a == b }
pub fn xor_eq128(a: bits[128], b: bits[128]) -> u1 { a == b }
pub fn xor_eq256(a: bits[256], b: bits[256]) -> u1 { a == b }
pub fn xor_eq512(a: bits[512], b: bits[512]) -> u1 { a == b }

// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

pub fn xor_parity8(x: u8) -> u1 { xor_reduce(x) }
pub fn xor_parity16(x: u16) -> u1 { xor_reduce(x) }
pub fn xor_parity32(x: u32) -> u1 { xor_reduce(x) }
pub fn xor_parity64(x: u64) -> u1 { xor_reduce(x) }
pub fn xor_parity128(x: bits[128]) -> u1 { xor_reduce(x) }
pub fn xor_parity256(x: bits[256]) -> u1 { xor_reduce(x) }
pub fn xor_parity512(x: bits[512]) -> u1 { xor_reduce(x) }

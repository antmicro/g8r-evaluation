// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

pub fn xor_gray8(x: u8) -> u8 {
    for (i, g): (u8, u8) in u8:0..u8:5 { g ^ (g >> (u8:1 << i)) }(x)
}
pub fn xor_gray16(x: u16) -> u16 {
    for (i, g): (u16, u16) in u16:0..u16:5 { g ^ (g >> (u16:1 << i)) }(x)
}
pub fn xor_gray32(x: u32) -> u32 {
    for (i, g): (u32, u32) in u32:0..u32:5 { g ^ (g >> (u32:1 << i)) }(x)
}
pub fn xor_gray64(x: u64) -> u64 {
    for (i, g): (u64, u64) in u64:0..u64:5 { g ^ (g >> (u64:1 << i)) }(x)
}
pub fn xor_gray128(x: bits[128]) -> bits[128] {
    for (i, g): (bits[128], bits[128]) in bits[128]:0..bits[128]:5 { g ^ (g >> (bits[128]:1 << i)) }(x)
}
pub fn xor_gray256(x: bits[256]) -> bits[256] {
    for (i, g): (bits[256], bits[256]) in bits[256]:0..bits[256]:5 { g ^ (g >> (bits[256]:1 << i)) }(x)
}
pub fn xor_gray512(x: bits[512]) -> bits[512] {
    for (i, g): (bits[512], bits[512]) in bits[512]:0..bits[512]:5 { g ^ (g >> (bits[512]:1 << i)) }(x)
}

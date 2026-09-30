// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

pub fn xor_crc8(crc: u8, data: u8) -> u8 {
    const POLY = u8:0xED;
    let crc = crc ^ (data as u8);
    for (_, c): (u8, u8) in u8:0..u8:8 {
        let mask = -(c & u8:1);
        (c >> 1) ^ (POLY & mask)
    }(crc)
}
pub fn xor_crc16(crc: u16, data: u16) -> u16 {
    const POLY = u16:0xEDB8;
    let crc = crc ^ (data as u16);
    for (_, c): (u16, u16) in u16:0..u16:16 {
        let mask = -(c & u16:1);
        (c >> 1) ^ (POLY & mask)
    }(crc)
}
pub fn xor_crc32(crc: u32, data: u32) -> u32 {
    const POLY = u32:0xEDB88320;
    let crc = crc ^ (data as u32);
    for (_, c): (u32, u32) in u32:0..u32:8 {
        let mask = -(c & u32:1);
        (c >> 1) ^ (POLY & mask)
    }(crc)
}
pub fn xor_crc64(crc: u64, data: u64) -> u64 {
    const POLY = u64:0xEDB88320EDB88320;
    let crc = crc ^ (data as u64);
    for (_, c): (u64, u64) in u64:0..u64:8 {
        let mask = -(c & u64:1);
        (c >> 1) ^ (POLY & mask)
    }(crc)
}
pub fn xor_crc128(crc: bits[128], data: bits[128]) -> bits[128] {
    const POLY = bits[128]:0xEDB88320EDB88320EDB88320EDB88320;
    let crc = crc ^ (data as bits[128]);
    for (_, c): (bits[128], bits[128]) in bits[128]:0..bits[128]:8 {
        let mask = -(c & bits[128]:1);
        (c >> 1) ^ (POLY & mask)
    }(crc)
}
pub fn xor_crc256(crc: bits[256], data: bits[256]) -> bits[256] {
    const POLY = bits[256]:0xEDB88320EDB88320EDB88320EDB88320EDB88320EDB88320EDB88320EDB88320;
    let crc = crc ^ (data as bits[256]);
    for (_, c): (bits[256], bits[256]) in bits[256]:0..bits[256]:8 {
        let mask = -(c & bits[256]:1);
        (c >> 1) ^ (POLY & mask)
    }(crc)
}
pub fn xor_crc512(crc: bits[512], data: bits[512]) -> bits[512] {
    const POLY = bits[512]:0xEDB88320EDB88320EDB88320EDB88320EDB88320EDB88320EDB88320EDB88320EDB88320EDB88320EDB88320EDB88320EDB88320EDB88320EDB88320EDB88320;
    let crc = crc ^ (data as bits[512]);
    for (_, c): (bits[512], bits[512]) in bits[512]:0..bits[512]:8 {
        let mask = -(c & bits[512]:1);
        (c >> 1) ^ (POLY & mask)
    }(crc)
}

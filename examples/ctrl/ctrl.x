// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

import std;

pub fn ctrl_clz32(x: u32) -> u6 { clz(x) as u6 }
pub fn ctrl_prio_enc32(x: u32) -> u5 { encode(one_hot(x, true) as u32) }
pub fn ctrl_decode5(x: u5) -> u32 { decode<u32>(x) }
pub fn ctrl_max4x16(a: u16, b: u16, c: u16, d: u16) -> u16 {
    let m0 = if a > b { a } else { b };
    let m1 = if c > d { c } else { d };
    if m0 > m1 { m0 } else { m1 }
}
pub fn ctrl_sat_add16(a: u16, b: u16) -> u16 {
    let (c, s) = std::uadd_with_overflow<u32:16>(a, b);
    if c { u16:0xffff } else { s }
}

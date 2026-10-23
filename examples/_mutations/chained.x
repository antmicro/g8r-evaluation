// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

pub fn baseline(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_01_add_to_sub ----
pub fn mut_01_add_to_sub(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_01_add_to_sub: `+` -> `-` in `add`
    let add = x - y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_02_add_to_mul ----
pub fn mut_02_add_to_mul(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_02_add_to_mul: `+` -> `*` in `add`
    let add = x * y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_03_add_to_div ----
pub fn mut_03_add_to_div(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_03_add_to_div: `+` -> `/` in `add`
    let add = x / y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_04_add_to_mod ----
pub fn mut_04_add_to_mod(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_04_add_to_mod: `+` -> `%` in `add`
    let add = x % y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_05_mul_to_add ----
pub fn mut_05_mul_to_add(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_05_mul_to_add: `*` -> `+` in `mul`
    let add = x + y;
    let mul = x64 + x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_06_mul_to_sub ----
pub fn mut_06_mul_to_sub(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_06_mul_to_sub: `*` -> `-` in `mul`
    let add = x + y;
    let mul = x64 - x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_07_mul_to_div ----
pub fn mut_07_mul_to_div(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_07_mul_to_div: `*` -> `/` in `mul`
    let add = x + y;
    let mul = x64 / x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_08_mul_to_mod ----
pub fn mut_08_mul_to_mod(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_08_mul_to_mod: `*` -> `%` in `mul`
    let add = x + y;
    let mul = x64 % x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_09_div_to_add ----
pub fn mut_09_div_to_add(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_09_div_to_add: `/` -> `+` in `div`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 + y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_10_div_to_sub ----
pub fn mut_10_div_to_sub(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_10_div_to_sub: `/` -> `-` in `div`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 - y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_11_div_to_mul ----
pub fn mut_11_div_to_mul(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_11_div_to_mul: `/` -> `*` in `div`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 * y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_12_div_to_mod ----
pub fn mut_12_div_to_mod(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_12_div_to_mod: `/` -> `%` in `div`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 % y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_13_mod_to_add ----
pub fn mut_13_mod_to_add(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_13_mod_to_add: `%` -> `+` in `mod`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 + y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_14_mod_to_sub ----
pub fn mut_14_mod_to_sub(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_14_mod_to_sub: `%` -> `-` in `mod`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 - y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_15_mod_to_mul ----
pub fn mut_15_mod_to_mul(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_15_mod_to_mul: `%` -> `*` in `mod`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 * y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_16_mod_to_div ----
pub fn mut_16_mod_to_div(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_16_mod_to_div: `%` -> `/` in `mod`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 / y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_17_sub_to_add ----
pub fn mut_17_sub_to_add(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_17_sub_to_add: `-` -> `+` in `sub`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 + y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_18_sub_to_mul ----
pub fn mut_18_sub_to_mul(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_18_sub_to_mul: `-` -> `*` in `sub`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 * y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_19_sub_to_div ----
pub fn mut_19_sub_to_div(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_19_sub_to_div: `-` -> `/` in `sub`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 / y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_20_sub_to_mod ----
pub fn mut_20_sub_to_mod(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_20_sub_to_mod: `-` -> `%` in `sub`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 % y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_21_shl_to_shr ----
pub fn mut_21_shl_to_shr(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_21_shl_to_shr: `<<` -> `>>` in `shleft`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 >> y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_22_shr_to_shl ----
pub fn mut_22_shr_to_shl(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_22_shr_to_shl: `>>` -> `<<` in `shright`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 << y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_23_and_to_or ----
pub fn mut_23_and_to_or(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_23_and_to_or: `&` -> `|` in `and`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 | y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_24_and_to_xor ----
pub fn mut_24_and_to_xor(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_24_and_to_xor: `&` -> `^` in `and`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 ^ y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_25_not_to_id ----
pub fn mut_25_not_to_id(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_25_not_to_id: `!` -> `` in `nand`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = (x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_26_not_to_sub ----
pub fn mut_26_not_to_sub(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_26_not_to_sub: `!` -> `-` in `nand`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = -(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_27_and_to_or ----
pub fn mut_27_and_to_or(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_27_and_to_or: `&` -> `|` in `nand`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 | y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_28_and_to_xor ----
pub fn mut_28_and_to_xor(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_28_and_to_xor: `&` -> `^` in `nand`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 ^ y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_29_or_to_and ----
pub fn mut_29_or_to_and(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_29_or_to_and: `|` -> `&` in `or`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 & y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_30_or_to_xor ----
pub fn mut_30_or_to_xor(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_30_or_to_xor: `|` -> `^` in `or`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 ^ y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_31_not_to_id ----
pub fn mut_31_not_to_id(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_31_not_to_id: `!` -> `` in `nor`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = (x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_32_not_to_sub ----
pub fn mut_32_not_to_sub(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_32_not_to_sub: `!` -> `-` in `nor`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = -(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_33_or_to_and ----
pub fn mut_33_or_to_and(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_33_or_to_and: `|` -> `&` in `nor`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 & y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_34_or_to_xor ----
pub fn mut_34_or_to_xor(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_34_or_to_xor: `|` -> `^` in `nor`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 ^ y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_35_xor_to_and ----
pub fn mut_35_xor_to_and(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_35_xor_to_and: `^` -> `&` in `xor`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 & y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_36_xor_to_or ----
pub fn mut_36_xor_to_or(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_36_xor_to_or: `^` -> `|` in `xor`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 | y64;
    let xnor = !(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_37_not_to_id ----
pub fn mut_37_not_to_id(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_37_not_to_id: `!` -> `` in `xnor`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = (x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_38_not_to_sub ----
pub fn mut_38_not_to_sub(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_38_not_to_sub: `!` -> `-` in `xnor`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = -(x64 ^ y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_39_xor_to_and ----
pub fn mut_39_xor_to_and(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_39_xor_to_and: `^` -> `&` in `xnor`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 & y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_40_xor_to_or ----
pub fn mut_40_xor_to_or(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_40_xor_to_or: `^` -> `|` in `xnor`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 | y64);
    let not = !x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_41_not_to_id ----
pub fn mut_41_not_to_id(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_41_not_to_id: `!` -> `` in `not`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

// ---- mut_42_not_to_sub ----
pub fn mut_42_not_to_sub(x: u32, y: u32) -> (u32, u64, u64, u64, u64, u64, u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64 ,u64) {
    let y64 = y as u64;
    let x64 = x as u64;

// MUT mut_42_not_to_sub: `!` -> `-` in `not`
    let add = x + y;
    let mul = x64 * x64;
    let div = x64 / y64;
    let mod = x64 % y64;
    let sub = x64 - y64;

    let shleft = x64 << y64;
    let shright = x64 >> y64;

    let and = x64 & y64;
    let nand = !(x64 & y64);
    let or = x64 | y64;
    let nor = !(x64 | y64);
    let xor = x64 ^ y64;
    let xnor = !(x64 ^ y64);
    let not = -x64;

    (add, mul, div, mod, sub, shleft, shright, and, nand, or, nor, xor, xnor, not)
}

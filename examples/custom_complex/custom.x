// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

// This is custom design, that does arithmetic/logic operations on 
// matricies and scalars, as well as shifts, conditionals, bit-extensions
// encoding and decoding.

import std;

struct DataBundle {
    x: u32,
    y: u32,
    z: u64,
    flag: bool,
}

struct NestedBundle {
    inner: DataBundle,
    count: u8,
    matrix: u16[4],
}

struct Triple {
    a: u32,
    b: u32,
    c: u32,
}

fn extract_fields(in_val: u64) -> DataBundle {
    let high = (in_val >> u32:32) as u32;
    let low = in_val as u32;
    DataBundle {
        x: high ^ low,
        y: high + low,
        z: in_val,
        flag: (in_val & u64:1) != u64:0,
    }
}

fn extract_nested(in_val: u64, data: u32[8]) -> NestedBundle {
    let base = extract_fields(in_val);
    let m0 = (data[0] as u16) ^ (base.x as u16);
    let m1 = (data[1] as u16) ^ (base.x as u16);
    let m2 = (data[2] as u16) ^ (base.x as u16);
    let m3 = (data[3] as u16) ^ (base.x as u16);
    NestedBundle {
        inner: base,
        count: (in_val & u64:0xFF) as u8,
        matrix: [m0, m1, m2, m3],
    }
}

fn arithmetic_ops(a: u32, b: u32) -> u32 {
    let sum = a + b;
    let diff = if a > b { a - b } else { b - a };
    let prod = (a as u64 * b as u64) as u32;
    let max_val = std::max(a, b);
    let min_val = std::min(a, b);
    let sat_sub = std::usub_or_zero(a, b);
    let overflow = std::uadd_with_overflow<u32:32>(a, b);
    sum + diff + prod + max_val - min_val + sat_sub
}

fn arithmetic_extended(a: u32, b: u32, c: u32) -> u32 {
    let t1 = arithmetic_ops(a, b);
    let t2 = arithmetic_ops(b, c);
    let t3 = arithmetic_ops(c, a);
    let combined = t1 ^ t2 ^ t3;
    std::max(combined, a) + std::min(combined, b)
}

fn bitwise_ops(data: u32) -> u32 {
    let not_v = !data;
    let and_v = data & u32:0xAAAA_5555;
    let or_v = data | u32:0x5555_AAAA;
    let xor_v = data ^ u32:0xFFFF_FFFF;
    let nand_v = !(data & u32:0x1234_5678);
    let nor_v = !(data | u32:0x8765_4321);
    let xnor_v = !(data ^ u32:0xDEAD_BEEF);
    let mixed = (and_v & or_v) | xor_v;
    mixed ^ nand_v ^ nor_v ^ xnor_v ^ not_v
}

fn bitwise_extended(data: u32, mask: u32) -> u32 {
    let base = bitwise_ops(data);
    let masked = base & mask;
    let rotated = std::rotr(masked as bits[32], u32:13 as bits[32]) as u32;
    rotated ^ (base >> u32:4)
}

fn shift_rotate_ops(value: u64, shift_amt: u32) -> u64 {
    let shl = value << shift_amt;
    let shr = value >> shift_amt;
    let rotr_val = std::rotr(value as bits[64], shift_amt as bits[64]) as u64;
    let rotl_val = std::rotl(value as bits[64], shift_amt as bits[64]) as u64;
    shl ^ shr ^ rotr_val ^ rotl_val
}

fn shift_extended(value: u64, amt1: u32, amt2: u32) -> u64 {
    let shifted1 = shift_rotate_ops(value, amt1);
    let shifted2 = shift_rotate_ops(value, amt2);
    shifted1 + shifted2
}

fn control_flow_ops(bundle: DataBundle) -> u32 {
    let result = if bundle.flag {
        if bundle.x > bundle.y { bundle.x - bundle.y } else { bundle.y - bundle.x }
    } else {
        bundle.x + bundle.y
    };
    let clz_val = clz(bundle.x as u32) as u32;
    let ctz_val = ctz(bundle.y as u32) as u32;
    result + clz_val + ctz_val
}

fn control_nested(bundle: DataBundle, depth: u8) -> u32 {
    let base = control_flow_ops(bundle);
    let modified = DataBundle {
        x: bundle.x ^ u32:0xCAFE,
        y: bundle.y + u32:1,
        z: bundle.z,
        flag: !bundle.flag,
    };
    let depth_factor = if depth > u8:0 { u32:1 } else { u32:0 };
    base + (modified.x as u32) * depth_factor
}

fn array_ops(data: u32[8]) -> u64 {
    let sum_acc = for (i, acc): (u32, u32) in u32:0..u32:8 { acc + data[i] }(u32:0);
    let max_val = for (i, acc): (u32, u32) in u32:0..u32:8 { std::max(data[i], acc) }(u32:0);
    (max_val as u64) + (sum_acc as u64)
}

fn array_extended(data: u32[8], factor: u32) -> u64 {
    let base = array_ops(data);
    let scaled = for (i, acc): (u32, u64) in u32:0..u32:8 { acc + (data[i] as u64 * factor as u64) }(u64:0);
    base ^ scaled
}

fn struct_manipulation(bundle: DataBundle) -> u64 {
    let modified = DataBundle {
        x: bundle.x ^ u32:0xDEAD,
        y: bundle.y + u32:1,
        z: bundle.z | u64:0xFFFF,
        flag: !bundle.flag,
    };
    modified.z + modified.x as u64 + if modified.flag { u64:1 } else { u64:0 }
}

fn struct_nested(nested: NestedBundle) -> u64 {
    let base = struct_manipulation(nested.inner);
    let matrix_sum = for (i, acc): (u32, u16) in u32:0..u32:4 { acc + nested.matrix[i] }(u16:0);
    base + matrix_sum as u64 + nested.count as u64
}

fn triple_ops(t1: Triple, t2: Triple) -> Triple {
    Triple {
        a: t1.a ^ t2.a,
        b: t1.b + t2.b,
        c: t1.c * t2.c,
    }
}

fn process_triples(data: u32[8]) -> u64 {
    let t1 = Triple { a: data[0], b: data[1], c: data[2] };
    let t2 = Triple { a: data[3], b: data[4], c: data[5] };
    let result = triple_ops(t1, t2);
    (result.a as u64) + (result.b as u64) + (result.c as u64)
}

fn encode_decode_ops(value: u32) -> u32 {
    let encoded = encode(value);
    let decoded = decode<u32>(encoded as u5);
    value ^ decoded
}

pub fn process_complex(in_val: u64, data: u32[8], flags: u8) -> u64 {
    let bundle = extract_fields(in_val);
    let nested = extract_nested(in_val, data);
    let arith = arithmetic_ops(bundle.x, bundle.y);
    let arith_ext = arithmetic_extended(arith, bundle.x, bundle.y);
    let bitwise = bitwise_ops(arith);
    let bitwise_ext = bitwise_extended(bitwise, flags as u32);
    let shift_rot = shift_rotate_ops(bundle.z, flags as u32);
    let shift_ext = shift_extended(bundle.z, flags as u32, (flags + u8:1) as u32);
    let control = control_flow_ops(bundle);
    let control_nest = control_nested(bundle, flags);
    let arr_result = array_ops(data);
    let arr_ext = array_extended(data, bundle.x);
    let struct_res = struct_manipulation(bundle);
    let struct_nest = struct_nested(nested);
    let triples = process_triples(data);
    let enc_dec = encode_decode_ops(arith);
    
    (arith_ext as u64) ^ (bitwise_ext as u64) ^ shift_rot ^ shift_ext ^ 
    (control as u64) ^ (control_nest as u64) ^ arr_result ^ arr_ext ^ 
    struct_res ^ struct_nest ^ triples ^ (enc_dec as u64) ^ (flags as u64)
}

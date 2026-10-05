// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

import std;

struct HashEntry {
    pos: u16,
    dist: u8,
}

struct MatchInfo {
    offset: u16,
    length: u8,
    lit: u8,
}

struct WindowState {
    data: u8[64],
    hash_table: u16[8],
}

fn rol32(v: u32, n: u32) -> u32 {
    let bits_v = v as bits[32];
    let bits_n = n as bits[32];
    std::rotl(bits_v, bits_n) as u32
}

fn ror32(v: u32, n: u32) -> u32 {
    let bits_v = v as bits[32];
    let bits_n = n as bits[32];
    std::rotr(bits_v, bits_n) as u32
}

fn hash4bytes(a: u8, b: u8, c: u8, d: u8) -> u16 {
    let w = (a as u32) | ((b as u32) << u32:8) | ((c as u32) << u32:16) | ((d as u32) << u32:24);
    let mixed = rol32(w, u32:13) ^ ror32(w, u32:7);
    (mixed & u32:0xFFFF) as u16
}

fn hash_window(state: WindowState, idx: u8) -> u16 {
    let result = if idx >= u8:60 { u16:0 } else { hash4bytes(state.data[idx], state.data[idx + u8:1], state.data[idx + u8:2], state.data[idx + u8:3]) };
    result
}

fn update_hash_table(state: WindowState, idx: u8) -> WindowState {
    let h = hash_window(state, idx);
    let entry_pos = h as u16;
    let new_table = state.hash_table;
    WindowState { data: state.data, hash_table: new_table }
}

fn find_match(state: WindowState, idx: u8) -> MatchInfo {
    let h = hash_window(state, idx);
    let table_idx = (h as u32) & u32:255;
    let prev_pos = state.hash_table[table_idx];
    let offset = if prev_pos != u16:0 { 
        if idx as u16 > prev_pos { idx as u16 - prev_pos } else { u16:0 }
    } else { u16:0 };
    let len = if offset != u16:0 { u8:4 } else { u8:0 };
    MatchInfo { offset: offset, length: len, lit: state.data[idx] }
}

fn encode_literal(lit: u8, match_len: u8) -> u32 {
    let base = lit as u32;
    let len_enc = (match_len as u32) << u32:8;
    let mixed = base ^ len_enc;
    rol32(mixed, u32:5) + ror32(mixed, u32:3)
}

fn encode_match(offset: u16, length: u8) -> u32 {
    let off = offset as u32;
    let len = length as u32;
    let combined = (off << u32:8) | len;
    std::rotr(combined as bits[32], u32:11 as bits[32]) as u32
}

fn entropy_mix(v: u32) -> u32 {
    let x = v ^ rol32(v, u32:13);
    let y = x + ror32(x, u32:7);
    y ^ (y >> u32:17)
}

fn process_block(state: WindowState, start_idx: u8) -> u32[4] {
    let m0 = find_match(state, start_idx);
    let m1 = find_match(state, start_idx + u8:1);
    let m2 = find_match(state, start_idx + u8:2);
    let m3 = find_match(state, start_idx + u8:3);
    
    let e0 = encode_literal(m0.lit, m0.length);
    let e1 = encode_literal(m1.lit, m1.length);
    let e2 = encode_literal(m2.lit, m2.length);
    let e3 = encode_literal(m3.lit, m3.length);
    
    [entropy_mix(e0), entropy_mix(e1), entropy_mix(e2), entropy_mix(e3)]
}

fn sliding_hash_chain(state: WindowState) -> u32[8] {
    let out0 = process_block(state, u8:0);
    let out1 = process_block(state, u8:4);
    let out2 = process_block(state, u8:8);
    let out3 = process_block(state, u8:12);
    
    let combined = for (i, acc): (u32, u32) in u32:0..u32:4 {
        acc + out0[i] ^ out1[i] ^ out2[i] ^ out3[i]
    }(u32:0);
    
    [combined, combined ^ u32:0xDEAD_BEEF, combined ^ u32:0xCAFE_BABE, combined ^ u32:0x1234_5678,
     combined + u32:1, combined + u32:2, combined + u32:3, combined + u32:4]
}

fn window_update(state: WindowState) -> WindowState {
    let updated = update_hash_table(state, u8:0);
    let shifted_data = for (i, acc): (u32, u8) in u32:0..u32:64 { acc }(u8:0);
    WindowState { data: state.data, hash_table: updated.hash_table }
}

fn complex_hash_mix(state: WindowState) -> u64 {
    let chain = sliding_hash_chain(state);
    let sum = for (i, acc): (u32, u64) in u32:0..u32:8 { acc + chain[i] as u64 }(u64:0);
    let mixed = sum ^ (sum << u32:13) ^ (sum >> u32:7);
    mixed
}

fn analyze_window(state: WindowState) -> u32 {
    let h0 = hash_window(state, u8:0);
    let h1 = hash_window(state, u8:16);
    let h2 = hash_window(state, u8:32);
    let h3 = hash_window(state, u8:48);
    
    let combined = (h0 as u32) ^ (h1 as u32) ^ (h2 as u32) ^ (h3 as u32);
    let clz_val = clz(combined) as u32;
    let ctz_val = ctz(combined) as u32;
    combined + clz_val + ctz_val
}

pub fn zstd_compress(in_data: u8[64], window: u8[256]) -> u32[16] {
    let state = WindowState {
        data: in_data,
        hash_table: [u16:0, u16:0, u16:0, u16:0, u16:0, u16:0, u16:0, u16:0],
    };
    
    let updated_state = window_update(state);
    let chain_result = sliding_hash_chain(updated_state);
    let hash_mix = complex_hash_mix(updated_state);
    let analysis = analyze_window(updated_state);
    
    let out0 = chain_result[0] ^ (hash_mix as u32);
    let out1 = chain_result[1] ^ analysis;
    let out2 = chain_result[2] + (hash_mix as u32);
    let out3 = chain_result[3] ^ analysis;
    
    [out0, out1, out2, out3,
     out0 ^ out1, out1 ^ out2, out2 ^ out3, out3 ^ out0,
     out0 + out1, out1 + out2, out2 + out3, out3 + out0,
     analysis, hash_mix as u32, (hash_mix >> u32:32) as u32, u32:0]
}

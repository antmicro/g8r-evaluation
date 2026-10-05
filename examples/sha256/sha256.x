// Copyright 2020 The XLS Authors
// Copyright 2026 Antmicro
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// File origin: https://github.com/google/xls/blob/93662d6077acad412cc4c92eeda2cabe690410b8/xls/examples/sha256.x

import std;

// ---
//
// SHA algorithm based on the description in:
//
// https://en.wikipedia.org/wiki/SHA-2#Pseudocode
//
// We attempt to mirror the pseudocode presented there fairly directly for ease
// of reproducing correct results.

pub type Digest = (u32, u32, u32, u32, u32, u32, u32, u32);

pub fn sha256_chunk_w_table(chunk: bits[512]) -> u32[64] {
    // Seed the "w" table with the message chunk.
    let w_init: u32[64] = (chunk ++ bits[1536]:0) as u32[64];

    // Build up the remaining values of the "w" table.
    // TODO(b/149962183): Make range go from 16 - 64 once counted for
    // ranges can start at values other than 0.
    let w: u32[64] = for (i, w): (u32, u32[64]) in u32:0..u32:48 {
        let w_im15: u32 = w[i + u32:16 - u32:15];
        let s_0: u32 = std::rotr(w_im15, u32:7) ^ std::rotr(w_im15, u32:18) ^ (w_im15 >> u32:3);
        let w_im2: u32 = w[i + u32:16 - u32:2];
        let s_1: u32 = std::rotr(w_im2, u32:17) ^ std::rotr(w_im2, u32:19) ^ (w_im2 >> u32:10);
        let value: u32 = w[i + u32:16 - u32:16] + s_0 + w[i + u32:16 - u32:7] + s_1;
        update(w, i + u32:16, value)
    }(w_init);
    w
}

// Returns the number of bits required to add on to turn bit_count into a
// multiple of 512.
fn compute_pad_bits(bit_count: u32) -> u32 {
    std::round_up_to_nearest(bit_count, u32:512) - bit_count
}

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

// File origin: https://github.com/google/xls/blob/93662d6077acad412cc4c92eeda2cabe690410b8/xls/examples/adler32/adler32.x

// Perform a (sequential) Adler-32 checksum over a single input byte.

pub fn adler32_seq(buffer: u8[4]) -> u32 {
    let a = u32:0;
    let b = u32:0;
    // Iterate only over input of length 1, for now.
    let (a, b) = for (i, (a, b)): (u8, (u32, u32)) in u8:0..u8:4 {
        let a = (a + (buffer[i] as u32)) % u32:65521;
        let b = (b + a) % u32:65521;
        (a, b)
    }((a, b));
    (b << u32:16) | a
}

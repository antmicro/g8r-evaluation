// Copyright 2021 The XLS Authors
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


// Parameterized fixed and floating point dot product
// implementations.

import float32;

type F32 = float32::F32;

pub fn dot_product_fixed32x32(a: sN[32][32], b: sN[32][32])
  -> sN[32]{
  for(idx, acc): (u32, sN[32]) in u32:0..32 {
    let partial_product = a[idx] * b[idx];
    acc + partial_product
  } (sN[32]:0)
}

pub fn dot_product_fixed64x8(a: sN[64][8], b: sN[64][8])
  -> sN[64]{
  for(idx, acc): (u64, sN[64]) in u64:0..8 {
    let partial_product = a[idx] * b[idx];
    acc + partial_product
  } (sN[64]:0)
}

pub fn dot_product_float32x8(a: F32[8], b: F32[8]) -> F32{
  for(idx, acc): (u32, F32) in u32:0..8 {
    let partial_product = float32::mul(a[idx], b[idx]);
    float32::add(acc, partial_product)
  } (float32::zero(u1:0))
}


pub fn dot_product_float32x16(a: F32[16], b: F32[16]) -> F32{
  for(idx, acc): (u16, F32) in u16:0..16 {
    let partial_product = float32::mul(a[idx], b[idx]);
    float32::add(acc, partial_product)
  } (float32::zero(u1:0))
}


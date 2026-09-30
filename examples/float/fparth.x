// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

import float32;
import bfloat16;

pub fn fp_f32_add(a: float32::F32, b: float32::F32) -> float32::F32 { float32::add(a, b) }
pub fn fp_f32_mul(a: float32::F32, b: float32::F32) -> float32::F32 { float32::mul(a, b) }
pub fn fp_bf16_mul(a: bfloat16::BF16, b: bfloat16::BF16) -> bfloat16::BF16 {
    bfloat16::mul(a, b)
}
pub fn fp_bf16_add(a: bfloat16::BF16, b: bfloat16::BF16) -> bfloat16::BF16 {
    bfloat16::add(a, b)
}

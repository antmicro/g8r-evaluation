// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

import std;

pub fn arith_smul8(a: s8, b: s8) -> s16 { std::smul(a, b) }
pub fn arith_smul16(a: s16, b: s16) -> s32 { std::smul(a, b) }
pub fn arith_smul32(a: s32, b: s32) -> s64 { std::smul(a, b) }

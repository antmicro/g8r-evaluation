// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

// arith_sum4x512: input vectors for the XLS reference and both netlists (see README.md).
module tb(input clk);
  logic [511:0] a, b, c, d;
  wire [513:0] out;
  `define SIM_IN {a, b, c, d}
  localparam logic [$bits(`SIM_IN)-1:0] VECS [8] = '{
    {{64{8'h00}}, {64{8'h00}}, {64{8'h00}}, {64{8'h00}}},
    {{64{8'hff}}, {64{8'hff}}, {64{8'hff}}, {64{8'hff}}},
    {{64{8'h55}}, {64{8'h55}}, {64{8'h55}}, {64{8'h55}}},
    {{64{8'h55}}, {64{8'haa}}, {64{8'h55}}, {64{8'haa}}},
    {{64{8'hff}}, 512'h1, 512'h1, 512'h1},
    {{8'h80, {63{8'h00}}}, {8'h80, {63{8'h00}}}, {8'h80, {63{8'h00}}}, {8'h80, {63{8'h00}}}},
    {{64{8'h3c}}, {64{8'hc9}}, {64{8'h96}}, {64{8'h0f}}},
    {512'h1, {8'h7f, {63{8'hff}}}, {8'h7f, {63{8'hff}}}, {8'h7f, {63{8'hff}}}}
  };
  `include "tb.svh"
endmodule

// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

// xor_ult512: input vectors for the XLS reference and both netlists (see README.md).
module tb(input clk);
  logic [511:0] a, b;
  wire out;
  `define SIM_IN {a, b}
  localparam logic [$bits(`SIM_IN)-1:0] VECS [8] = '{
    {{64{8'h00}}, {64{8'h00}}},
    {{64{8'hff}}, {64{8'hff}}},
    {{64{8'h55}}, {64{8'h55}}},
    {{64{8'h55}}, {64{8'haa}}},
    {{64{8'hff}}, 512'h1},
    {{8'h80, {63{8'h00}}}, {8'h80, {63{8'h00}}}},
    {{64{8'h3c}}, {64{8'hc9}}},
    {512'h1, {8'h7f, {63{8'hff}}}}
  };
  `include "tb.svh"
endmodule

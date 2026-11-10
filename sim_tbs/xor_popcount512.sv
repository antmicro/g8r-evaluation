// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

// xor_popcount512: input vectors for the XLS reference and both netlists (see README.md).
module tb(input clk);
  logic [511:0] x;
  wire [9:0] out;
  `define SIM_IN x
  localparam logic [$bits(`SIM_IN)-1:0] VECS [6] = '{
    {64{8'h00}},
    {64{8'hff}},
    {64{8'h55}},
    {8'h80, {63{8'h00}}},
    {64{8'h3c}},
    512'h1
  };
  `include "tb.svh"
endmodule

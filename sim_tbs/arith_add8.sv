// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

// arith_add8: input vectors for the XLS reference and both netlists (see README.md).
module tb(input clk);
  logic [7:0] a, b;
  wire [7:0] out;
  `define SIM_IN {a, b}
  localparam logic [$bits(`SIM_IN)-1:0] VECS [8] = '{
    {8'h00, 8'h00},
    {8'hff, 8'hff},
    {8'h55, 8'h55},
    {8'h55, 8'haa},
    {8'hff, 8'h01},
    {8'h80, 8'h80},
    {8'h3c, 8'hc9},
    {8'h01, 8'h7f}
  };
  `include "tb.svh"
endmodule

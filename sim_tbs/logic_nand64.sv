// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

// logic_nand64: input vectors for the XLS reference and both netlists (see README.md).
module tb(input clk);
  logic [63:0] a, b;
  wire [63:0] out;
  `define SIM_IN {a, b}
  localparam logic [$bits(`SIM_IN)-1:0] VECS [8] = '{
    {64'h0000000000000000, 64'h0000000000000000},
    {64'hffffffffffffffff, 64'hffffffffffffffff},
    {64'h5555555555555555, 64'h5555555555555555},
    {64'h5555555555555555, 64'haaaaaaaaaaaaaaaa},
    {64'hffffffffffffffff, 64'h0000000000000001},
    {64'h8000000000000000, 64'h8000000000000000},
    {64'h3c3c3c3c3c3c3c3c, 64'hc9c9c9c9c9c9c9c9},
    {64'h0000000000000001, 64'h7fffffffffffffff}
  };
  `include "tb.svh"
endmodule

// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

// arith_smul32: input vectors for the XLS reference and both netlists (see README.md).
module tb(input clk);
  logic [31:0] a, b;
  wire [63:0] out;
  `define SIM_IN {a, b}
  localparam logic [$bits(`SIM_IN)-1:0] VECS [8] = '{
    {32'h00000000, 32'h00000000},
    {32'hffffffff, 32'hffffffff},
    {32'h55555555, 32'h55555555},
    {32'h55555555, 32'haaaaaaaa},
    {32'hffffffff, 32'h00000001},
    {32'h80000000, 32'h80000000},
    {32'h3c3c3c3c, 32'hc9c9c9c9},
    {32'h00000001, 32'h7fffffff}
  };
  `include "tb.svh"
endmodule

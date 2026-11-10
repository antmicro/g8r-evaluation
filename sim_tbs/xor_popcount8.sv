// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

// xor_popcount8: input vectors for the XLS reference and both netlists (see README.md).
module tb(input clk);
  logic [7:0] x;
  wire [3:0] out;
  `define SIM_IN x
  localparam logic [$bits(`SIM_IN)-1:0] VECS [6] = '{
    8'h00,
    8'hff,
    8'h55,
    8'h80,
    8'h3c,
    8'h01
  };
  `include "tb.svh"
endmodule

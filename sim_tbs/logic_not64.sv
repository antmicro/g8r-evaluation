// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

// logic_not64: input vectors for the XLS reference and both netlists (see README.md).
module tb(input clk);
  logic [63:0] a;
  wire [63:0] out;
  `define SIM_IN a
  localparam logic [$bits(`SIM_IN)-1:0] VECS [6] = '{
    64'h0000000000000000,
    64'hffffffffffffffff,
    64'h5555555555555555,
    64'h8000000000000000,
    64'h3c3c3c3c3c3c3c3c,
    64'h0000000000000001
  };
  `include "tb.svh"
endmodule

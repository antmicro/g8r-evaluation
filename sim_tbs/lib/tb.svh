// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

// Body shared by every testbench: instantiates `SIM_TOP (whichever netlist
// was compiled in), applies one VECS entry to `SIM_IN per clock and prints the
// output. check-g8r-yosys-equiv.sh compares the printouts of the netlists.
// No delays, so it also runs on old Verilator (4.x) driven by main.cpp.
`SIM_TOP dut(.*);
int i = 0;
initial `SIM_IN = VECS[0];
always @(posedge clk) begin
  $display("vec %0d: in=%h out=%h", i, VECS[i], out);
  i = i + 1;
  if (i == $size(VECS)) $finish;
  else `SIM_IN = VECS[i];
end

// Copyright (c) 2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

// Toggles the testbench clock until $finish. Works with Verilator 4.x and 5.x.
#include "Vtb.h"
#include "verilated.h"

double sc_time_stamp() { return 0; }

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vtb* tb = new Vtb;
    for (tb->clk = 0; !Verilated::gotFinish(); tb->clk = !tb->clk)
        tb->eval();
    tb->final();
    delete tb;
    return 0;
}

// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

wire [3:0] memenb;
wire [9:0] adr_mem;
wire [11:0] adr_cpu;
wire [15:0] cpdatin, cpdatout, memdatin0, memdatin1, memdatin2, memdatin3, memdatout;
wire cpuen, cpurw, memrwb, enkbd, endisp, rst, clk;

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/

soc_config mprj (
`ifdef USE_POWER_PINS
    .vccd1(vccd1),	// User area 1 1.8V power
    .vssd1(vssd1),	// User area 1 digital ground
`endif

    .user_clock2(user_clock2),
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),

    // MGMT SoC Wishbone Slave

    .wbs_cyc_i(wbs_cyc_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_ack_o(wbs_ack_o),
    .wbs_dat_o(wbs_dat_o),

    // Logic Analyzer

    .la_data_in(la_data_in),
    .la_data_out(la_data_out),
    .la_oenb (la_oenb),

    // IO Pads

    .io_in (io_in),
    .io_out(io_out),
    .io_oeb(io_oeb),

    // CPU specific
    .addr_from_cpu(adr_cpu),
    .data_from_cpu(cpdatout),
    .data_to_cpu(cpdatin),
    .addr_to_mem(adr_mem),
    .data_from_mem0(memdatin0),
    .data_from_mem1(memdatin1),
    .data_from_mem2(memdatin2),
    .data_from_mem3(memdatin3),
    .data_to_mem(memdatout),
    .rw_from_cpu(cpurw),
    .en_from_cpu(cpuen),
    .rw_to_mem(memrwb),
    .en_to_memB(memenb),
    .en_keyboard(enkbd),
    .en_display(endisp),
    .soc_clk(clk),
    .soc_rst(rst),

    // IRQ
    .irq(user_irq)
);

cpu cpu0 (
`ifdef USE_POWER_PINS
    .vccd1(vccd1),	// User area 1 1.8V power
    .vssd1(vssd1),	// User area 1 digital ground
`endif

    .clkin(clk),
    .addr(adr_cpu),
    .datain(cpdatin), 
    .dataout(cpdatout),
    .en_inp(enkbd),
    .en_out(endisp),
    .rdwr(cpurw),
    .en(cpuen),
    .rst(rst),
    .keyboard(io_in[37:30]),
    .display(io_out[29:22]) 
);

sky130_sram_1kbyte_1rw1r_8x1024_8 #(.NUM_WMASKS(2)) memLword0 (
`ifdef USE_POWER_PINS
    .vccd1(vccd1),	// User area 1 1.8V power
    .vssd1(vssd1),	// User area 1 digital ground
`endif
    .clk0(clk),
    .addr0(adr_mem),
    .din0(memdatout[7:0]),
    .dout0(memdatin0[7:0]),
    .web0(memrwb),
    .csb0(memenb[0]),
    .wmask0({cpuen, cpuen})
);
    sky130_sram_1kbyte_1rw1r_8x1024_8 #(.NUM_WMASKS(2)) memHword0 (
`ifdef USE_POWER_PINS
    .vccd1(vccd1),	// User area 1 1.8V power
    .vssd1(vssd1),	// User area 1 digital ground
`endif
    .clk0(clk),
    .addr0(adr_mem),
    .din0(memdatout[15:8]),
    .dout0(memdatin0[15:8]),
    .web0(memrwb),
    .csb0(memenb[0]),
    .wmask0({cpuen, cpuen})
);

sky130_sram_1kbyte_1rw1r_8x1024_8 #(.NUM_WMASKS(2)) memLword1 (
`ifdef USE_POWER_PINS
    .vccd1(vccd1),	// User area 1 1.8V power
    .vssd1(vssd1),	// User area 1 digital ground
`endif
    .clk0(clk),
    .addr0(adr_mem),
    .din0(memdatout[7:0]),
    .dout0(memdatin1[7:0]),
    .web0(memrwb),
    .csb0(memenb[1]),
    .wmask0({cpuen, cpuen})
);

    sky130_sram_1kbyte_1rw1r_8x1024_8 #(.NUM_WMASKS(2)) memHword1 (
`ifdef USE_POWER_PINS
    .vccd1(vccd1),	// User area 1 1.8V power
    .vssd1(vssd1),	// User area 1 digital ground
`endif
    .clk0(clk),
    .addr0(adr_mem),
    .din0(memdatout[15:8]),
    .dout0(memdatin1[15:8]),
    .web0(memrwb),
    .csb0(memenb[1]),
    .wmask0({cpuen, cpuen})
);

sky130_sram_1kbyte_1rw1r_8x1024_8 #(.NUM_WMASKS(2)) memLword2 (
`ifdef USE_POWER_PINS
    .vccd1(vccd1),	// User area 1 1.8V power
    .vssd1(vssd1),	// User area 1 digital ground
`endif
    .clk0(clk),
    .addr0(adr_mem),
    .din0(memdatout[7:0]),
    .dout0(memdatin2[7:0]),
    .web0(memrwb),
    .csb0(memenb[2]),
    .wmask0({cpuen, cpuen})
);

    sky130_sram_1kbyte_1rw1r_8x1024_8 #(.NUM_WMASKS(2)) memHword2 (
`ifdef USE_POWER_PINS
    .vccd1(vccd1),	// User area 1 1.8V power
    .vssd1(vssd1),	// User area 1 digital ground
`endif
    .clk0(clk),
    .addr0(adr_mem),
    .din0(memdatout[15:8]),
    .dout0(memdatin2[15:8]),
    .web0(memrwb),
    .csb0(memenb[2]),
    .wmask0({cpuen, cpuen})
);

sky130_sram_1kbyte_1rw1r_8x1024_8 #(.NUM_WMASKS(2)) memLword3 (
`ifdef USE_POWER_PINS
    .vccd1(vccd1),	// User area 1 1.8V power
    .vssd1(vssd1),	// User area 1 digital ground
`endif
    .clk0(clk),
    .addr0(adr_mem),
    .din0(memdatout[7:0]),
    .dout0(memdatin3[7:0]),
    .web0(memrwb),
    .csb0(memenb[3]),
    .wmask0({cpuen, cpuen})
);

    sky130_sram_1kbyte_1rw1r_8x1024_8 #(.NUM_WMASKS(2)) memHword3 (
`ifdef USE_POWER_PINS
    .vccd1(vccd1),	// User area 1 1.8V power
    .vssd1(vssd1),	// User area 1 digital ground
`endif
    .clk0(clk),
    .addr0(adr_mem),
    .din0(memdatout[15:8]),
    .dout0(memdatin3[15:8]),
    .web0(memrwb),
    .csb0(memenb[3]),
    .wmask0({cpuen, cpuen})
);

endmodule	// user_project_wrapper

`default_nettype wire

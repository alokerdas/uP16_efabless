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
 *
 *-------------------------------------------------------------
 */

module soc_config #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    input user_clock2,
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

    // IRQ
    output [2:0] irq,

    // CPU specific
    input rw_from_cpu,
    input en_from_cpu,
    input [11:0] addr_from_cpu,
    input [15:0] data_from_cpu,
    output [15:0] data_to_cpu,
    input [15:0] data_from_mem,
    output [15:0] data_to_mem,
    output [9:0] addr_to_mem,
    output rw_to_mem,
    output en_to_mem,
    output en_keyboard,
    output en_display,
    output soc_rst,
    output soc_clk
);
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire rw, n;

    // IRQ
    assign irq = 3'b000;	// Unused

    // IO
    assign io_oeb[37:30] = 8'hFF; // input
    assign io_oeb[29:22] = 8'h00; // output
    assign io_oeb[21:18] = 8'hFF; // input

    // LA
    // if la_data_in[0] is input, then wbclk or usrclk can be used. Else io_in[19] is the clock
    assign soc_clk = la_oenb[0] ? (la_data_in[0] ? user_clock2 : wb_clk_i) : io_in[19];
    // if la_data_in[1] is input, then wbrst or io_in[18] can be used. Else io_in[18] is the reset
    assign soc_rst = la_oenb[1] ? (la_data_in[1] ? io_in[18] : wb_rst_i) : io_in[18];
    // Enable display and keyboard by LA or io_in 21/20
    assign en_keyboard = la_oenb[2] ? la_data_in[2] : io_in[21];
    assign en_display = la_oenb[3] ? la_data_in[3] : io_in[20];

    // Provision to read/write ram from LA
    assign data_to_mem = la_data_in[127] ? la_data_in[126:111] : data_from_cpu;
    assign addr_to_mem = la_data_in[127] ? la_data_in[110:101] : addr_from_cpu[9:0];
    assign rw_to_mem = la_data_in[127] ? la_data_in[100] : ~rw_from_cpu; // active low for openram
    assign en_to_mem = la_data_in[127] ? la_data_in[99] : ~en_from_cpu; // active low for openram
    assign data_to_cpu = data_from_mem;
    assign la_data_out[98:83] = data_from_mem;

endmodule

`default_nettype wire
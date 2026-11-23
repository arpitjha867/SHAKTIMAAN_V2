// Bluespec wrapper, created by Import BVI Wizard
// Created on: Thu Nov 22 18:16:30 IST 2018
// Created by: neel
// Bluespec version: 2018.10.beta1 2018-10-17 e1df8052c

package bram_1rw;
interface Ifc_bram_1rw#(numeric type addr_width, numeric type data_width, numeric type memsize);
	(*always_enabled*)
	method Action request (Bit#(1) wea, Bit#(addr_width) addra, Bit#(data_width) dina);
	(*always_enabled*)
	method Bit#(data_width) response ();
`ifdef testmode
	(*always_enabled*)
	method Action ma_test_mode(Bool test_mode);
`endif
endinterface

import "BVI" bram_1rw =
module mkbram_1rw  (Ifc_bram_1rw#(addr_width, data_width, memsize));

	parameter ADDR_WIDTH = valueOf(addr_width);
	parameter DATA_WIDTH = valueOf(data_width);
	parameter MEMSIZE = valueOf(memsize);

	default_clock clk_clka;
	default_reset rst_rst_n;

`ifdef core_clkgate
	input_clock clk_clka (clka,gate)  <- exposeCurrentClock;
`else
	input_clock clk_clka (clka)  <- exposeCurrentClock;
`endif
	input_reset rst_rst_n (rst_n) clocked_by(clk_clka)  <- exposeCurrentReset;

	method request (wea , addra /*ADDR_WIDTH-1:0*/, dina /*DATA_WIDTH-1:0*/)
		 enable(ena) clocked_by(clk_clka) reset_by(rst_rst_n);
	method douta /* DATA_WIDTH-1 : 0 */ response ()
		 clocked_by(clk_clka) reset_by(rst_rst_n);
`ifdef testmode
	method ma_test_mode (test_mode) enable((*inhigh*)test_mode_enable) clocked_by(clk_clka) reset_by(rst_rst_n);
`endif
	schedule request C request;
	schedule request CF response;
	schedule response CF response;
`ifdef testmode
	schedule request CF ma_test_mode;
	schedule response CF ma_test_mode;
`endif
endmodule

endpackage

// Copyright (c) 2025 IIT- Madras
// Copyright (c) 2000-2011 Bluespec, Inc.

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

`ifdef  BSV_WARN_REGFILE_ADDR_RANGE
`else
`define BSV_WARN_REGFILE_ADDR_RANGE 0 
`endif



`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

`ifdef BSV_ASYNC_RESET
 `define BSV_ARESET_EDGE_META or `BSV_RESET_EDGE RST
`else
 `define BSV_ARESET_EDGE_META
`endif


// Multi-ported Register File
module RegFile(CLK,
               ADDR_IN, D_IN, WE,RST,
               ADDR_1, D_OUT_1,
               ADDR_2, D_OUT_2,
               ADDR_3, D_OUT_3,
               ADDR_4, D_OUT_4,
               ADDR_5, D_OUT_5
               );
   parameter                   addr_width = 3;
   parameter                   data_width = 32;
   parameter                   lo = 0;
   parameter                   hi = 7;

   input                       CLK;
   input                       RST;
   input [addr_width - 1 : 0]  ADDR_IN;
   input [data_width - 1 : 0]  D_IN;
   input                       WE;

   input [addr_width - 1 : 0]  ADDR_1;
   output [data_width - 1 : 0] D_OUT_1;

   input [addr_width - 1 : 0]  ADDR_2;
   output [data_width - 1 : 0] D_OUT_2;

   input [addr_width - 1 : 0]  ADDR_3;
   output [data_width - 1 : 0] D_OUT_3;

   input [addr_width - 1 : 0]  ADDR_4;
   output [data_width - 1 : 0] D_OUT_4;

   input [addr_width - 1 : 0]  ADDR_5;
   output [data_width - 1 : 0] D_OUT_5;

   integer                     i;
   
   (* RAM_STYLE = "DISTRIBUTED" *)     
   reg [data_width - 1 : 0]    arr[lo:hi];


`ifdef BSV_NO_INITIAL_BLOCKS
`else // not BSV_NO_INITIAL_BLOCKS
   // synopsys translate_off
   initial
     begin : init_block
        integer                     i;          // temporary for generate reset value
        for (i = lo; i <= hi; i = i + 1) begin
           arr[i] = {((data_width + 1)/2){2'b10}} ;
        end
     end // initial begin
   // synopsys translate_on
`endif // BSV_NO_INITIAL_BLOCKS

if(hi == 255) begin : gen_blk_1
   always@(posedge CLK `BSV_ARESET_EDGE_META)
     begin
      if (RST == `BSV_RESET_VALUE) begin     
	        arr[0] <= 0;
          arr[1] <= 0;
          arr[2] <= 0;
          arr[3] <= 0;
          arr[4] <= 0;
          arr[5] <= 0;
          arr[6] <= 0;
          arr[7] <= 0;
          arr[8] <= 0;
          arr[9] <= 0;
          arr[10] <= 0;
          arr[11] <= 0;
          arr[12] <= 0;
          arr[13] <= 0;
          arr[14] <= 0;
          arr[15] <= 0;
          arr[16] <= 0;
          arr[17] <= 0;
          arr[18] <= 0;
          arr[19] <= 0;
          arr[20] <= 0;
          arr[21] <= 0;
          arr[22] <= 0;
          arr[23] <= 0;
          arr[24] <= 0;
          arr[25] <= 0;
          arr[26] <= 0;
          arr[27] <= 0;
          arr[28] <= 0;
          arr[29] <= 0;
          arr[30] <= 0;
          arr[31] <= 0;
          arr[32] <= 0;
          arr[33] <= 0;
          arr[34] <= 0;
          arr[35] <= 0;
          arr[36] <= 0;
          arr[37] <= 0;
          arr[38] <= 0;
          arr[39] <= 0;
          arr[40] <= 0;
          arr[41] <= 0;
          arr[42] <= 0;
          arr[43] <= 0;
          arr[44] <= 0;
          arr[45] <= 0;
          arr[46] <= 0;
          arr[47] <= 0;
          arr[48] <= 0;
          arr[49] <= 0;
          arr[50] <= 0;
          arr[51] <= 0;
          arr[52] <= 0;
          arr[53] <= 0;
          arr[54] <= 0;
          arr[55] <= 0;
          arr[56] <= 0;
          arr[57] <= 0;
          arr[58] <= 0;
          arr[59] <= 0;
          arr[60] <= 0;
          arr[61] <= 0;
          arr[62] <= 0;
          arr[63] <= 0;
          arr[64] <= 0;
          arr[65] <= 0;
          arr[66] <= 0;
          arr[67] <= 0;
          arr[68] <= 0;
          arr[69] <= 0;
          arr[70] <= 0;
          arr[71] <= 0;
          arr[72] <= 0;
          arr[73] <= 0;
          arr[74] <= 0;
          arr[75] <= 0;
          arr[76] <= 0;
          arr[77] <= 0;
          arr[78] <= 0;
          arr[79] <= 0;
          arr[80] <= 0;
          arr[81] <= 0;
          arr[82] <= 0;
          arr[83] <= 0;
          arr[84] <= 0;
          arr[85] <= 0;
          arr[86] <= 0;
          arr[87] <= 0;
          arr[88] <= 0;
          arr[89] <= 0;
          arr[90] <= 0;
          arr[91] <= 0;
          arr[92] <= 0;
          arr[93] <= 0;
          arr[94] <= 0;
          arr[95] <= 0;
          arr[96] <= 0;
          arr[97] <= 0;
          arr[98] <= 0;
          arr[99] <= 0;
          arr[100] <= 0;
          arr[101] <= 0;
          arr[102] <= 0;
          arr[103] <= 0;
          arr[104] <= 0;
          arr[105] <= 0;
          arr[106] <= 0;
          arr[107] <= 0;
          arr[108] <= 0;
          arr[109] <= 0;
          arr[110] <= 0;
          arr[111] <= 0;
          arr[112] <= 0;
          arr[113] <= 0;
          arr[114] <= 0;
          arr[115] <= 0;
          arr[116] <= 0;
          arr[117] <= 0;
          arr[118] <= 0;
          arr[119] <= 0;
          arr[120] <= 0;
          arr[121] <= 0;
          arr[122] <= 0;
          arr[123] <= 0;
          arr[124] <= 0;
          arr[125] <= 0;
          arr[126] <= 0;
          arr[127] <= 0;
          arr[128] <= 0;
          arr[129] <= 0;
          arr[130] <= 0;
          arr[131] <= 0;
          arr[132] <= 0;
          arr[133] <= 0;
          arr[134] <= 0;
          arr[135] <= 0;
          arr[136] <= 0;
          arr[137] <= 0;
          arr[138] <= 0;
          arr[139] <= 0;
          arr[140] <= 0;
          arr[141] <= 0;
          arr[142] <= 0;
          arr[143] <= 0;
          arr[144] <= 0;
          arr[145] <= 0;
          arr[146] <= 0;
          arr[147] <= 0;
          arr[148] <= 0;
          arr[149] <= 0;
          arr[150] <= 0;
          arr[151] <= 0;
          arr[152] <= 0;
          arr[153] <= 0;
          arr[154] <= 0;
          arr[155] <= 0;
          arr[156] <= 0;
          arr[157] <= 0;
          arr[158] <= 0;
          arr[159] <= 0;
          arr[160] <= 0;
          arr[161] <= 0;
          arr[162] <= 0;
          arr[163] <= 0;
          arr[164] <= 0;
          arr[165] <= 0;
          arr[166] <= 0;
          arr[167] <= 0;
          arr[168] <= 0;
          arr[169] <= 0;
          arr[170] <= 0;
          arr[171] <= 0;
          arr[172] <= 0;
          arr[173] <= 0;
          arr[174] <= 0;
          arr[175] <= 0;
          arr[176] <= 0;
          arr[177] <= 0;
          arr[178] <= 0;
          arr[179] <= 0;
          arr[180] <= 0;
          arr[181] <= 0;
          arr[182] <= 0;
          arr[183] <= 0;
          arr[184] <= 0;
          arr[185] <= 0;
          arr[186] <= 0;
          arr[187] <= 0;
          arr[188] <= 0;
          arr[189] <= 0;
          arr[190] <= 0;
          arr[191] <= 0;
          arr[192] <= 0;
          arr[193] <= 0;
          arr[194] <= 0;
          arr[195] <= 0;
          arr[196] <= 0;
          arr[197] <= 0;
          arr[198] <= 0;
          arr[199] <= 0;
          arr[200] <= 0;
          arr[201] <= 0;
          arr[202] <= 0;
          arr[203] <= 0;
          arr[204] <= 0;
          arr[205] <= 0;
          arr[206] <= 0;
          arr[207] <= 0;
          arr[208] <= 0;
          arr[209] <= 0;
          arr[210] <= 0;
          arr[211] <= 0;
          arr[212] <= 0;
          arr[213] <= 0;
          arr[214] <= 0;
          arr[215] <= 0;
          arr[216] <= 0;
          arr[217] <= 0;
          arr[218] <= 0;
          arr[219] <= 0;
          arr[220] <= 0;
          arr[221] <= 0;
          arr[222] <= 0;
          arr[223] <= 0;
          arr[224] <= 0;
          arr[225] <= 0;
          arr[226] <= 0;
          arr[227] <= 0;
          arr[228] <= 0;
          arr[229] <= 0;
          arr[230] <= 0;
          arr[231] <= 0;
          arr[232] <= 0;
          arr[233] <= 0;
          arr[234] <= 0;
          arr[235] <= 0;
          arr[236] <= 0;
          arr[237] <= 0;
          arr[238] <= 0;
          arr[239] <= 0;
          arr[240] <= 0;
          arr[241] <= 0;
          arr[242] <= 0;
          arr[243] <= 0;
          arr[244] <= 0;
          arr[245] <= 0;
          arr[246] <= 0;
          arr[247] <= 0;
          arr[248] <= 0;
          arr[249] <= 0;
          arr[250] <= 0;
          arr[251] <= 0;
          arr[252] <= 0;
          arr[253] <= 0;
          arr[254] <= 0;
          arr[255] <= 0;
         end

       else if (WE) begin  
          arr[ADDR_IN] <= D_IN;  
     end // always@ (posedge CLK)
    end
  end

  else if(hi == 63) begin : gen_blk_2
   always@(posedge CLK `BSV_ARESET_EDGE_META)
     begin
      if (RST == `BSV_RESET_VALUE) begin     
	        arr[0] <= 0;
          arr[1] <= 0;
          arr[2] <= 0;
          arr[3] <= 0;
          arr[4] <= 0;
          arr[5] <= 0;
          arr[6] <= 0;
          arr[7] <= 0;
          arr[8] <= 0;
          arr[9] <= 0;
          arr[10] <= 0;
          arr[11] <= 0;
          arr[12] <= 0;
          arr[13] <= 0;
          arr[14] <= 0;
          arr[15] <= 0;
          arr[16] <= 0;
          arr[17] <= 0;
          arr[18] <= 0;
          arr[19] <= 0;
          arr[20] <= 0;
          arr[21] <= 0;
          arr[22] <= 0;
          arr[23] <= 0;
          arr[24] <= 0;
          arr[25] <= 0;
          arr[26] <= 0;
          arr[27] <= 0;
          arr[28] <= 0;
          arr[29] <= 0;
          arr[30] <= 0;
          arr[31] <= 0;
          arr[32] <= 0;
          arr[33] <= 0;
          arr[34] <= 0;
          arr[35] <= 0;
          arr[36] <= 0;
          arr[37] <= 0;
          arr[38] <= 0;
          arr[39] <= 0;
          arr[40] <= 0;
          arr[41] <= 0;
          arr[42] <= 0;
          arr[43] <= 0;
          arr[44] <= 0;
          arr[45] <= 0;
          arr[46] <= 0;
          arr[47] <= 0;
          arr[48] <= 0;
          arr[49] <= 0;
          arr[50] <= 0;
          arr[51] <= 0;
          arr[52] <= 0;
          arr[53] <= 0;
          arr[54] <= 0;
          arr[55] <= 0;
          arr[56] <= 0;
          arr[57] <= 0;
          arr[58] <= 0;
          arr[59] <= 0;
          arr[60] <= 0;
          arr[61] <= 0;
          arr[62] <= 0;
          arr[63] <= 0;
         end  
       else if (WE) begin  
          arr[ADDR_IN] <= D_IN;  
     end // always@ (posedge CLK)
    end
  end
        
  else if(hi == 31) begin : gen_blk_3
   always@(posedge CLK `BSV_ARESET_EDGE_META)
     begin
      if (RST == `BSV_RESET_VALUE) begin     
	        arr[0] <= 0;
          arr[1] <= 0;
          arr[2] <= 0;
          arr[3] <= 0;
          arr[4] <= 0;
          arr[5] <= 0;
          arr[6] <= 0;
          arr[7] <= 0;
          arr[8] <= 0;
          arr[9] <= 0;
          arr[10] <= 0;
          arr[11] <= 0;
          arr[12] <= 0;
          arr[13] <= 0;
          arr[14] <= 0;
          arr[15] <= 0;
          arr[16] <= 0;
          arr[17] <= 0;
          arr[18] <= 0;
          arr[19] <= 0;
          arr[20] <= 0;
          arr[21] <= 0;
          arr[22] <= 0;
          arr[23] <= 0;
          arr[24] <= 0;
          arr[25] <= 0;
          arr[26] <= 0;
          arr[27] <= 0;
          arr[28] <= 0;
          arr[29] <= 0;
          arr[30] <= 0;
          arr[31] <= 0;
          
         end
       else if (WE) begin  
          arr[ADDR_IN] <= D_IN;  
     end // always@ (posedge CLK)
  end
  end

  else if(hi == 7) begin : gen_blk_4
   always@(posedge CLK `BSV_ARESET_EDGE_META)
     begin
      if (RST == `BSV_RESET_VALUE) begin     
	        arr[0] <= 0;
          arr[1] <= 0;
          arr[2] <= 0;
          arr[3] <= 0;
          arr[4] <= 0;
          arr[5] <= 0;
          arr[6] <= 0;
          arr[7] <= 0;
         end   
       else if (WE) begin  
          arr[ADDR_IN] <= D_IN;  
     end // always@ (posedge CLK)
    end
  end

   assign D_OUT_1 = arr[ADDR_1];
   assign D_OUT_2 = arr[ADDR_2];
   assign D_OUT_3 = arr[ADDR_3];
   assign D_OUT_4 = arr[ADDR_4];
   assign D_OUT_5 = arr[ADDR_5];

   // synopsys translate_off
   always@(posedge CLK)
     begin : runtime_check
        reg enable_check;
        enable_check = `BSV_WARN_REGFILE_ADDR_RANGE ;
        if ( enable_check )
           begin
              if (( ADDR_1 < lo ) || (ADDR_1 > hi) )
                $display( "Warning: RegFile: %m -- Address port 1 is out of bounds: %h", ADDR_1 ) ;
              if (( ADDR_2 < lo ) || (ADDR_2 > hi) )
                $display( "Warning: RegFile: %m -- Address port 2 is out of bounds: %h", ADDR_2 ) ;
              if (( ADDR_3 < lo ) || (ADDR_3 > hi) )
                $display( "Warning: RegFile: %m -- Address port 3 is out of bounds: %h", ADDR_3 ) ;
              if (( ADDR_4 < lo ) || (ADDR_4 > hi) )
                $display( "Warning: RegFile: %m -- Address port 4 is out of bounds: %h", ADDR_4 ) ;
              if (( ADDR_5 < lo ) || (ADDR_5 > hi) )
                $display( "Warning: RegFile: %m -- Address port 5 is out of bounds: %h", ADDR_5 ) ;
              if ( WE && ( ADDR_IN < lo ) || (ADDR_IN > hi) )
                $display( "Warning: RegFile: %m -- Write Address port is out of bounds: %h", ADDR_IN ) ;
           end
     end
   // synopsys translate_on

endmodule

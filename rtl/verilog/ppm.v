//----------------------------------------------------------------------------
// Copyright (C) 2014 , Atsushi Sasaki
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the authors nor the names of its contributors
//       may be used to endorse or promote products derived from this software
//       without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
// THE POSSIBILITY OF SUCH DAMAGE
//
//----------------------------------------------------------------------------
//
// *File Name: ppm.v
// 
// *Module Description:
//                       Pulse Position Modulation (PPM) Module
//
// *Author(s):
//              - Atsushi Sasaki,    atsushi.sasaki@aselectroworks.com
//
//----------------------------------------------------------------------------
// $Rev: 1.00 $
// $LastChangedBy: Atsushi Sasaki $
// $LastChangedDate: 2014-09-01 $
//----------------------------------------------------------------------------
module ppm (
	  dat_i
	, clk_i
	, stb_i
	, dat_o
	, busy_o
);

//
// Definition
//
	`define IDLE  3'b000
	`define START 3'b001
	`define TRANS_ON_STATE 3'b010
	`define TRANS_OFF_STATE 3'b011
	`define STOP  3'b100
	
//
// Paramters
//
	parameter DATA_WIDTH = 32;
	parameter COUNTER_WIDTH = 5; // Must Set 2^COUNTER_WIDTH > DATA_WIDTH
	parameter SYMCOUNTER_WIDTH = 6; // Must Set 2^SYMCOUNTER_WIDTH > Bit Width of belows
	parameter READER_ON_WIDTH = 6'd16;
	parameter READER_OFF_WIDTH = 6'd8;
	parameter DATA0_ON_WIDTH = 6'd1;
	parameter DATA0_OFF_WIDTH = 6'd1;
	parameter DATA1_ON_WIDTH = 6'd1;
	parameter DATA1_OFF_WIDTH = 6'd3;
	parameter STOP_ON_WIDTH = 6'd1;
	parameter STOP_OFF_WIDTH = 6'd40;
	
//
// I/O
//
	input [DATA_WIDTH-1:0] dat_i;
	input clk_i;
	input stb_i;
	output reg dat_o;
	output reg busy_o;
	
//
// Internal Wires, Registers
//
	reg [COUNTER_WIDTH-1:0] bitcnt;
	reg [SYMCOUNTER_WIDTH-1:0] symcnt;
	reg [2:0] state;
	wire stb_i_n = ~stb_i;
	
//
// Module
//
	always @ (posedge clk_i or posedge stb_i_n)
	begin
		if(stb_i_n) 
		begin 
			dat_o <= 1'b0;
			bitcnt <= 0;
			symcnt <= 0;
			busy_o <= 1'b0;
			state <= `START;
		end
		else
		begin
			case(state)
				`IDLE: 
				begin
					busy_o <= 1'b0;
				end	
				`START: 
				begin
					if(symcnt=={SYMCOUNTER_WIDTH{1'b0}})
					begin
						busy_o <= 1'b1;
						dat_o <= 1'b1;
						symcnt <= symcnt + 1'b1;
					end
					else if(symcnt==READER_ON_WIDTH)
					begin
						dat_o <= 1'b0;
						symcnt <= symcnt + 1'b1;
					end
					else if(symcnt==READER_ON_WIDTH+READER_OFF_WIDTH-6'd1)
					begin
						symcnt <= {SYMCOUNTER_WIDTH{1'b0}}; 
						state <= `TRANS_ON_STATE;
					end
					else 
					begin 
						symcnt <= symcnt + 1'b1;
					end
				end
				`TRANS_ON_STATE: 
				begin
					// First Symbol
					if(symcnt=={SYMCOUNTER_WIDTH{1'b0}})
					begin
						dat_o <= 1'b1;
						symcnt <= symcnt + 1'b1;
					end
					else if((dat_i[DATA_WIDTH-1-bitcnt]&&symcnt==DATA1_ON_WIDTH) || (!dat_i[DATA_WIDTH-1-bitcnt]&&symcnt==DATA0_ON_WIDTH))
					begin
						dat_o <= 1'b0;
						symcnt <= {SYMCOUNTER_WIDTH{1'b0}};
						state <= `TRANS_OFF_STATE;
					end
					else 
					begin 
						symcnt <= symcnt + 1'b1;
					end
				end
				`TRANS_OFF_STATE:
				begin
					if((dat_i[DATA_WIDTH-1-bitcnt]&&symcnt==DATA1_OFF_WIDTH-1) || (!dat_i[DATA_WIDTH-1-bitcnt]&&symcnt==DATA0_OFF_WIDTH-1))
					begin
						dat_o <= 1'b1;
						symcnt <= {SYMCOUNTER_WIDTH{1'b0}} + 1'b1;
						bitcnt <= bitcnt + 1'b1;
						if(bitcnt==DATA_WIDTH-1'b1)
						begin
							state <= `STOP;
						end
						else 
						begin
							state <= `TRANS_ON_STATE;
						end
					end
					else 
					begin
							symcnt <= symcnt + 1'b1;
					end
				end
				`STOP:
				begin
					if(symcnt=={SYMCOUNTER_WIDTH{1'b0}})
					begin
						dat_o <= 1'b1;
						symcnt <= symcnt + 1'b1;
					end
					else if(symcnt==STOP_ON_WIDTH) 
					begin
						dat_o <= 1'b0;
						symcnt <= symcnt + 1'b1;
					end
					else if(symcnt==STOP_ON_WIDTH+STOP_OFF_WIDTH-1'd1) 
					begin
						symcnt <= {SYMCOUNTER_WIDTH{1'b0}};
						state <= `IDLE;
					end
					else 
					begin
						symcnt <= symcnt + 1'b1;
					end
				end
			endcase
		end	 
	end 

endmodule

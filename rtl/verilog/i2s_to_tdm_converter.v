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
// *File Name: i2s_to_tdm_converter.v
// 
// *Module Description:
//                       I2S to TDM Converter
//
// *Author(s):
//              - Atsushi Sasaki,    atsushi.sasaki@aselectroworks.com
//
//----------------------------------------------------------------------------
// $Rev: 1.00 $
// $LastChangedBy: Atsushi Sasaki $
// $LastChangedDate: 2014-06-06 $
//----------------------------------------------------------------------------

module i2s_to_tdm_comverter(
	rst_i, 
	mck_i, 
	bck_i, 
	lrck_i, 
	dat_i, 
	sck_o, 
	fsync_o, 
	dat_o
);

//
// Parameters
//

//
// I/O Ports
// 
	input rst_i;		// reset
	input mck_i;		// 256fs
	input bck_i;		// 64fs
	input lrck_i;		// fs
	input [3:0] dat_i;
	output sck_o;		// 256fs
	output fsync_o;		// fs
	output reg dat_o;	// multi ch output
	
//
// Wires, Registers
//
	reg rst_int;
	wire rst = rst_i | rst_int;
	reg [8:0] bit_cnt; // input data bit counter
	wire bank = bit_cnt[8];
//	reg bank;			// FIFO Buffer Bank
	wire sck = mck_i; 	// internal system clock
	assign sck_o = sck;
	wire [5:0] inbit_cnt = bit_cnt[7:2];
//
// module
//

	// LRCK Negedge Detector
	reg d_lrck_1, d_lrck_2, d_lrck_3, d_lrck_4, d_lrck_5, d_lrck_6; 	// Delayed LRCK
	wire lrck_negedge_flag;		// Frame Sync for LRCK Falling Edge
	assign lrck_negedge_flag = (d_lrck_4 ^ d_lrck_6) & ~d_lrck_4;
	always @ (posedge sck or posedge rst_i) begin
		if(rst_i) begin
			d_lrck_1 <= 1'b0;
			d_lrck_2 <= 1'b0;
			d_lrck_3 <= 1'b0;
			d_lrck_5 <= 1'b0;
		end
		else begin
			d_lrck_1 <= lrck_i;
			d_lrck_2 <= d_lrck_1;
			d_lrck_3 <= d_lrck_2;
			d_lrck_5 <= d_lrck_4;
		end
	end
	always @ (negedge sck or posedge rst_i) begin
		if(rst_i) begin
			d_lrck_4 <= 1'b0;
			d_lrck_6 <= 1'b0;
		end
		else begin
			d_lrck_4 <= d_lrck_3;
			d_lrck_6 <= d_lrck_5;
		end
	end

	// Internal Async Reset
	always @ (negedge d_lrck_4 or posedge rst_i) begin
		if(rst_i) begin
			rst_int <= 1'b1;
		end
		else begin
			if(&bit_cnt[7:0]) begin
				rst_int <= 1'b0;
			end
			else begin
				rst_int <= 1'b1;
			end
		end
	end

	// Bit counter 
	always @ (negedge sck or posedge rst) begin
		if(rst) begin
			bit_cnt <= 9'b111111111;
		end
		else begin 
			bit_cnt <= bit_cnt + 1'b1;
		end
	end
		
	// Input Buffer
	reg [255:0] fifo_a;
	reg [255:0] fifo_b;
	always @ (posedge bck_i or posedge rst) begin
		if(rst) begin
			fifo_a <= 256'b0;
			fifo_b <= 256'b0;
		end
		else begin
			if(!bank) begin
				fifo_a[255-bit_cnt[7:2]] <= dat_i[0];
				fifo_a[191-bit_cnt[7:2]] <= dat_i[1];
				fifo_a[127-bit_cnt[7:2]] <= dat_i[2];
				fifo_a[63-bit_cnt[7:2]] <= dat_i[3];
			end
			else begin
				fifo_b[255-bit_cnt[7:2]] <= dat_i[0];
				fifo_b[191-bit_cnt[7:2]] <= dat_i[1];
				fifo_b[127-bit_cnt[7:2]] <= dat_i[2];
				fifo_b[63-bit_cnt[7:2]] <= dat_i[3];
			end
		end
	end
	
	// TDM Generator
	always @ (posedge sck or posedge rst) begin
		if(rst) begin
			dat_o <= 1'b0; 
		end
		else begin
			if(!bank) begin
				dat_o <= fifo_b[255-bit_cnt[7:0]];
			end
			else begin
				dat_o <= fifo_a[255-bit_cnt[7:0]];
			end
		end
	end
	
	assign fsync_o = &bit_cnt[7:0];
	
	
endmodule
			
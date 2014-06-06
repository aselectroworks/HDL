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
// *File Name: tdm_to_i2s_converter.v
// 
// *Module Description:
//                       TDM to I2S Converter
//
// *Author(s):
//              - Atsushi Sasaki,    atsushi.sasaki@aselectroworks.com
//
//----------------------------------------------------------------------------
// $Rev: 1.00 $
// $LastChangedBy: Atsushi Sasaki $
// $LastChangedDate: 2014-06-06 $
//----------------------------------------------------------------------------

module tdm_to_i2s_converter(
	rst_i, 
	sck_i, 
	fsync_i, 
	dat_i, 
	mck_o, 
	bck_o, 
	lrck_o, 
	dat_o 
);

//
// Parameters
//

//
// I/O Ports
//
	input rst_i;
	input sck_i;
	input fsync_i;
	input dat_i;
	output mck_o;
	output bck_o;
	output lrck_o;
	output reg [3:0] dat_o;
	
//
// Wires, Registers
//
	assign rst = rst_i;
	
//
// Modules
//
	// Shifted Frame Sync
	reg s_fsync;
	
	always @ (posedge sck_i or posedge rst) begin
		if(rst) begin
			s_fsync <= 1'b0;
		end
		else begin
			s_fsync <= fsync_i;
		end
	end
	// Bit Counter
	reg [8:0] bit_cnt;
	always @ (negedge sck_i or posedge rst) begin
		if(rst) begin
			bit_cnt <= 9'b111111111;
		end
		else begin
			if(s_fsync) begin
				bit_cnt <= {~bit_cnt[8], 8'b0};
			end
			else begin
				bit_cnt <= bit_cnt + 1'b1;
			end
		end
	end
	// Input Data Assign
	reg [63:0] dat_0_a, dat_0_b;
	reg [63:0] dat_1_a, dat_1_b;
	reg [63:0] dat_2_a, dat_2_b;
	reg [63:0] dat_3_a, dat_3_b;
	always @ (posedge sck_i or posedge rst) begin
		if(rst) begin
			dat_0_a <= 64'b0;
			dat_1_a <= 64'b0;
			dat_2_a <= 64'b0;
			dat_3_a <= 64'b0;
			dat_0_b <= 64'b0;
			dat_1_b <= 64'b0;
			dat_2_b <= 64'b0;
			dat_3_b <= 64'b0;
		end
		else begin
			if(bit_cnt[8]) begin
				case(bit_cnt[7:6]) 
					2'b00: 
						begin
							dat_0_a[63-bit_cnt[5:0]] <= dat_i;
						end
					2'b01: 
						begin
							dat_1_a[63-bit_cnt[5:0]] <= dat_i;
						end
					2'b10: 
						begin
							dat_2_a[63-bit_cnt[5:0]] <= dat_i;
						end
					2'b11: 
						begin
							dat_3_a[63-bit_cnt[5:0]] <= dat_i;
						end
				endcase
			end
			else begin
				case(bit_cnt[7:6]) 
					2'b00: 
						begin
							dat_0_b[63-bit_cnt[5:0]] <= dat_i;
						end
					2'b01: 
						begin
							dat_1_b[63-bit_cnt[5:0]] <= dat_i;
						end
					2'b10: 
						begin
							dat_2_b[63-bit_cnt[5:0]] <= dat_i;
						end
					2'b11: 
						begin
							dat_3_b[63-bit_cnt[5:0]] <= dat_i;
						end
				endcase
			end
		end
	end
	
	// I2S Clock Generator
	assign mck_o = sck_i;
	assign bck_o = bit_cnt[1];
	assign lrck_o = bit_cnt[7];
	
	always @ (negedge bck_o or posedge rst) begin
		if(rst) begin
			dat_o <= 4'b0;
		end
		else begin
			if(bit_cnt[8]) begin
				dat_o <= {dat_3_b[63-bit_cnt[7:2]], dat_2_b[63-bit_cnt[7:2]], dat_1_b[63-bit_cnt[7:2]], dat_0_b[63-bit_cnt[7:2]]};
			end
			else begin
				dat_o <= {dat_3_a[63-bit_cnt[7:2]], dat_2_a[63-bit_cnt[7:2]], dat_1_a[63-bit_cnt[7:2]], dat_0_a[63-bit_cnt[7:2]]};
			end
		end
	end
	
endmodule

//----------------------------------------------------------------------------
// Copyright (C) 2013 , Atsushi Sasaki
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
// *File Name: dit.v
// 
// *Module Description:
//                       Digital Audio Interface Transmitter(DIT) Module
//
// *Author(s):
//              - Atsushi Sasaki,    atsushi.sasaki@aselectroworks.com
//
//----------------------------------------------------------------------------
// $Rev: 1.00 $
// $LastChangedBy: Atsushi Sasaki $
// $LastChangedDate: 2013-11-28 $
//----------------------------------------------------------------------------

module dit(
	  mck_i
	, bck_i
	, lrck_i
	, dat_i
	, mck_ratio_i
	, vbit_i
	, mute_i
	, ch_stat7_0_i									// Channel Status Input
	, ch_stat15_8_i
	, ch_stat23_16_i
	, ch_stat31_24_i
	, ch_stat39_32_i
//	, nrst_i
	, rst_i
	, spdif_o
//	, err_o
);

//
// Paramters
//

//
// I/O Ports
//
	input mck_i;									// Master Clock input
	input bck_i;									// Bit Clock input
	input lrck_i;									// LR Clock input
	input dat_i;									// Data input
	input [1:0] mck_ratio_i;						// Master Clock Ratio(00:128fs, 01:256fs, 10:512fs, 11:Reserved)
	input vbit_i;									// Validity Bit Data('0':Valid, '1':Invalid)
	input mute_i;									// Output Mute Data Flag
	input [7:0] ch_stat7_0_i;						// Channel Status Input
	input [7:0] ch_stat15_8_i;
	input [7:0] ch_stat23_16_i;
	input [7:0] ch_stat31_24_i;
	input [7:0] ch_stat39_32_i;
//	input nrst_i;
	input rst_i; 									// Active Hi Reset
//	wire rst_i = ~nrst_i;
	output spdif_o;
//	output reg err_o;								// Error Output
	
//
// Wires, Registers
//
	wire [7:0] B_PREAMBLE = 8'b00010111;
	wire [7:0] M_PREAMBLE = 8'b01000111;
	wire [7:0] W_PREAMBLE = 8'b00100111;
//	wire [191:0] ch_stat = {{132{1'b0}}, 8'b10000000, 8'b10000010, 8'b00000000, 8'b01111010, 8'b00000100};
	reg [39:0] ch_stat_buf;
	wire [191:0] ch_stat = {{132{1'b0}}, ch_stat_buf};
	reg [14:0] cnt;
	wire slot_state = cnt[0];						// Slot State
	wire [4:0] bit_cnt = cnt[5:1];					// Bit Counter
	wire [7:0] frame_cnt = cnt[14:7];				// Frame Counter 
	wire subframe = cnt[6];							// Subframe Channel
//	wire [23:0] adat = 24'b0;						// Sample Audio Data
	reg p_bit;										// Parity Bit Data
	wire v_bit = vbit_i;							// Validity Bit Data('0':Valid, '1':Invalid)
	
	reg [1:0] d_clk;								// Divided Clocks
	wire s_clk = (mck_ratio_i==2'b00) ? mck_i :
					(mck_ratio_i==2'b01) ? d_clk[0] :
					(mck_ratio_i==2'b10) ? d_clk[1] : 1'b0;			// System Clock(=128fs)
//	wire b_clk = d_clk[MCK_RATIO];					// Bit Clock
	
	reg encdat;										// Encoding Data
	reg spdif;										// Encoded SPDIF Output
	assign spdif_o = spdif;

//
// Modules, Components
//
	// Internal Async Reset
	reg rst_int;
	wire rst = rst_i | rst_int;
	always @ (negedge lrck_i or posedge rst_i) begin
		if(rst_i) begin
			rst_int <= 1'b1;
		end
		else begin
			if(&bit_cnt[4:0]) begin
				rst_int <= 1'b0;
			end
			else begin
				rst_int <= 1'b1;
			end
		end
	end
	// System Clock & Bit Clock Generator
	always @ (posedge mck_i or posedge rst) begin
		if(rst) begin
			d_clk <= 2'b0;
		end
		else begin
			d_clk <= d_clk + 1'b1;
		end
	end
	// LRCK Edge Detector
	reg lrck_q0, lrck_q1;
	wire lrck_edge_flag = lrck_i ^ lrck_q1;
	always @ (posedge bck_i or posedge rst) begin
		if(rst) begin
			lrck_q0 <= 1'b0;
		end
		else begin
			lrck_q0 <= lrck_i;
		end
	end
	always @ (negedge bck_i or posedge rst) begin
		if(rst) begin
			lrck_q1 <= 1'b0;
		end
		else begin
			lrck_q1 <= lrck_q0;
		end
	end
	// System Clock Counter 
	always @ (posedge s_clk or posedge rst) begin
		if(rst) begin
			cnt <= 15'b111111111111111;
		end
		else begin
			if({frame_cnt, subframe, bit_cnt, slot_state}=={8'd191, 1'b1, 5'b11111, 1'b1}) begin	// count 192frame, 2nd subframe, 32-bit, after half biphase code
				cnt <= 15'b0;
			end
			else begin
				cnt <= cnt + 1'b1;
			end
		end
	end
	// Bit Counter and RAM(Enable for I2S format)
	reg [4:0] i2s_bit_cnt;
	reg lr;						// 0=Left Ch., 1=Right Ch.
	reg [23:0] dat_l, dat_r;
	reg mute;
	always @ (posedge bck_i or posedge rst) begin
		if(rst) begin
			i2s_bit_cnt <= 5'b11111;
			lr <= 1'b0;
			dat_l <= 24'b0;
			dat_r <= 24'b0;
			mute <= 1'b0;
		end
		else begin
			if(lrck_edge_flag) begin
				i2s_bit_cnt <= 5'b0;
				mute <= mute_i;
			end
			else begin
				if(i2s_bit_cnt!=5'd24) begin
					i2s_bit_cnt <= i2s_bit_cnt + 1'b1;
				end
			end
			if(~lr) begin
				dat_l[23-i2s_bit_cnt] <= dat_i & ~mute;
			end
			else begin
				dat_r[23-i2s_bit_cnt] <= dat_i & ~mute;
			end
			lr <= lrck_i;
		end
	end
	always @ (negedge lrck_edge_flag or posedge rst) begin
		if(rst) begin
			ch_stat_buf <= 40'b0;
		end
		else begin
			ch_stat_buf <= {ch_stat39_32_i, ch_stat31_24_i, ch_stat23_16_i, ch_stat15_8_i, ch_stat7_0_i};
		end
	end
	// SPDIF Bit Encoder
	always @ (posedge s_clk or posedge rst) begin
		if(rst) begin
			spdif <= 1'b0;
			p_bit <= 1'b0;
		end
		else begin
			if(bit_cnt==5'd0) begin
				p_bit <= 1'b0;			// Parity Clear
			end
			if(bit_cnt<5'd4) begin
				// Preamble
				if(subframe) begin	// Subframe 2
					// W Preamble
					spdif <= W_PREAMBLE[{bit_cnt[1:0], slot_state}];
				end
				else if(frame_cnt==8'b0) begin
					// B Preamble
					spdif <= B_PREAMBLE[{bit_cnt[1:0], slot_state}];
				end
				else begin
					// M Preamble
					spdif <= M_PREAMBLE[{bit_cnt[1:0], slot_state}];
				end
			end
			else begin
				spdif <= (!slot_state) ? ~spdif : 			// invert @ data boundary
								(encdat) ? ~spdif : spdif;		// invert if encode data is '1'
				p_bit <= p_bit + (encdat & slot_state);	// calculate P bit @ every encoded data boundary
			end
		end
	end
	// BiPhase Mark Coding Data Setting
	always @ (negedge s_clk or posedge rst) begin
		if(rst) begin
			encdat <= 1'b0;
		end
		else begin
			if(bit_cnt>5'd3 && bit_cnt<5'd28) begin
				if(lrck_i) begin
					encdat <= dat_l[bit_cnt-4];
				end
				else begin
					encdat <= dat_r[bit_cnt-4];
				end
				//encdat <= 1'b0;
			end
			else if(bit_cnt==5'd28) begin
				encdat <= v_bit;
			end
			else if(bit_cnt==5'd29) begin
				//encdat <= u_dat[frame_cnt];
				encdat <= 1'b0;
			end
			else if(bit_cnt==5'd30) begin
				encdat <= ch_stat[frame_cnt];
			end
			else if(bit_cnt==5'd31) begin
				encdat <= p_bit;
			end
		end
	end
/*		
// Output Error Detection Block
	
	// SPDIF Edge Detection Block
	reg edgeclr;
	wire edgedet = spdif_o ^ edgeclr;
	always @ (negedge mck_i or posedge rst_i) begin
		if(rst_i) begin
			edgeclr <= 1'b0;
		end
		else begin
			edgeclr <= spdif_o;
		end
	end
	// ERROR Counter
	wire err_cntclk = s_clk & ~err_o;	// count when negeted error flag
	reg [2:0] err_cnt;
	wire cnt_clr = edgedet | rst_i;
	always @ (negedge err_cntclk or posedge cnt_clr) begin
		if(cnt_clr) begin
			err_cnt <= 3'b0;
		end
		else begin
			err_cnt <= err_cnt + 1'b1;
		end
	end
	always @ (posedge err_cnt[2] or posedge rst_i) begin		// Assert Error Flag when invalid biphase coding
	  if(rst_i) begin
	    err_o <= 1'b0;
	  end
	  else begin
	    err_o <= 1'b1;
	  end
	end
*/
	
endmodule

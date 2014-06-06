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
// *File Name: fs_counter.v
// 
// *Module Description:
//                       Sampling Frequency Counter for Audio Clock
//
// *Author(s):
//              - Atsushi Sasaki,    atsushi.sasaki@aselectroworks.com
//
//----------------------------------------------------------------------------
// $Rev: 1.00 $
// $LastChangedBy: Atsushi Sasaki $
// $LastChangedDate: 2014-02-27 $
//----------------------------------------------------------------------------

module fs_counter(
	  refclk_i
	, fsclk_i
	, rst_i
	, result_o
);

//
// I/O Ports
//
	input refclk_i;			// refclk_i must be 24.576MHz
	input fsclk_i;			// sampling clock frequency input
	input rst_i;			// Active Hi Reset
	output [3:0] result_o;	// 0000:32k, 0001:44.1k, 0010:48k, 0100:64k, 0101:88.2k, 0110:96k
							// 1000:128k, 1001:176.4k, 1010:192k, 1100:256k, 1101:352.8k: 1110:384k

//
// Wires & Registers
	reg [9:0] cnt;
	reg [9:0] l_cnt;
	reg [2:0] s_fsclk;
//
// Module
//
	//Defective for Meta-stable
	always @ (posedge rst_i or negedge refclk_i) begin
		if(rst_i) begin
			s_fsclk[0] <= 1'b0;
		end
		else begin
			s_fsclk[2:0] <= {s_fsclk[1:0], fsclk_i};
		end
	end
	//Negative Edge Detector
	wire edgedet = (s_fsclk[1] ^ s_fsclk[2]) & ~s_fsclk[1];

	always @ (posedge refclk_i or posedge rst_i) begin
		if(rst_i) begin
			l_cnt[9:0] <= 10'b0;
			cnt[9:0] <= 10'b0;
		end
		else begin
			if(edgedet) begin
				l_cnt[9:0] <= cnt[9:0];
				cnt[9:0] <= 10'b0;
			end
			else begin
				cnt[9:0] <= cnt[9:0] + 1'b1;
			end
		end
	end
	
	assign result_o = (l_cnt[9:0] >= 10'd662) ? 4'b0000 :
							(l_cnt[9:0] >= 10'd534 && l_cnt[9:0] < 662) ? 4'b0001 :
							(l_cnt[9:0] >= 10'd448 && l_cnt[9:0] < 534) ? 4'b0010 :
							(l_cnt[9:0] >= 10'd331 && l_cnt[9:0] < 448) ? 4'b0100 :
							(l_cnt[9:0] >= 10'd267 && l_cnt[9:0] < 331) ? 4'b0101 :
							(l_cnt[9:0] >= 10'd224 && l_cnt[9:0] < 267) ? 4'b0110 :
							(l_cnt[9:0] >= 10'd165 && l_cnt[9:0] < 224) ? 4'b1000 :
							(l_cnt[9:0] >= 10'd133 && l_cnt[9:0] < 165) ? 4'b1001 :
							(l_cnt[9:0] >= 10'd112 && l_cnt[9:0] < 133) ? 4'b1010 :
							(l_cnt[9:0] >= 10'd82 && l_cnt[9:0] < 112) ? 4'b1100 :
							(l_cnt[9:0] >= 10'd66 && l_cnt[9:0] < 82) ? 4'b1101 :
							(l_cnt[9:0] >= 10'd1 && l_cnt[9:0] < 66) ? 4'b1110 :
							4'b1111;
			
	
	
			
endmodule 

	
			
		
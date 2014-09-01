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
// *File Name: xorshift.v
// 
// *Module Description:
//                       xorshift random generator module
//
// *Author(s):
//              - Atsushi Sasaki,    atsushi.sasaki@aselectroworks.com
//
//----------------------------------------------------------------------------
// $Rev: 1.00 $
// $LastChangedBy: Atsushi Sasaki $
// $LastChangedDate: 2014-09-01 $
//----------------------------------------------------------------------------
module xorshift (
	  clk_i
	, rst_i
	, en_i
	, rnd_o
);

//
// Parameters
//
	parameter SEED_X = 32'd123456789;
	parameter SEED_Y = 32'd362436069;
	parameter SEED_Z = 32'd521288629;
	parameter SEED_W = 32'd88675123;
//
// I/O Ports
//
	input clk_i;
	input rst_i;
	input en_i;
	output [31:0] rnd_o;
	
//
// Wires, Registers
//
	reg [31:0] x, y, z, w, t;
	assign rnd_o = w;
	
//
// Module 
//
	always @ (posedge clk_i or posedge rst_i) 
	begin 
		if(rst_i) 
		begin 
			x <= SEED_X;
			y <= SEED_Y;
			z <= SEED_Z;
			w <= SEED_W;
		end
		else if(en_i) 
		begin
			t = x^(x<<11);
			x <= y;
			y <= z;
			z <= w;
			w <= (w^(w>>19))^(t^(t>>8));
		end
	end

endmodule

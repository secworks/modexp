//======================================================================
//
// blockmem_rw32_r64.v
// -------------------
// Test implementation of a block memory that has different data
// widths on external (api) and internal ports.
// Author: Joachim Strombergson, Peter Magnusson
// Copyright (c) 2015, Assured AB
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

module blockmem_rw32_r64(
                         input wire           clk,

                         input wire           api_wr,
                         input wire  [07 : 0] api_addr,
                         input wire  [31 : 0] api_wr_data,
                         output wire [31 : 0] api_rd_data,

                         input wire  [06 : 0] internal_addr,
                         output wire [63 : 0] internal_rd_data
                        );


  //----------------------------------------------------------------
  // Regs and memories.
  //----------------------------------------------------------------
  reg [31 : 0] mem0 [0 : 127];
  reg [31 : 0] mem1 [0 : 127];

  wire mem0_we;
  wire mem1_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [31 : 0] tmp0_api_rd_data;
  reg [31 : 0] tmp1_api_rd_data;
  reg [31 : 0] tmp0_int_rd_data;
  reg [31 : 0] tmp1_int_rd_data;


  //----------------------------------------------------------------
  // Assignmets.
  //----------------------------------------------------------------
  assign api_rd_data      = api_addr[0] ? tmp1_api_rd_data : tmp0_api_rd_data;
  assign internal_rd_data = {tmp1_int_rd_data, tmp0_int_rd_data};

  assign mem0_we = api_wr & ~api_addr[0];
  assign mem1_we = api_wr & api_addr[0];


  //----------------------------------------------------------------
  // Reg updates.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin : reg_update_mem0
      if (mem0_we)
        mem0[api_addr[7 : 1]] <= api_wr_data;

      tmp0_api_rd_data <= mem0[api_addr[7 : 1]];
      tmp0_int_rd_data <= mem0[internal_addr];
    end

  always @ (posedge clk)
    begin : reg_update_mem1
      if (mem1_we)
        mem1[api_addr[7 : 1]] <= api_wr_data;

      tmp1_api_rd_data <= mem1[api_addr[7 : 1]];
      tmp1_int_rd_data <= mem1[internal_addr];
    end

endmodule // blockmem_rw32_r64

//======================================================================
// eof blockmem_rw32_r64.v
//======================================================================

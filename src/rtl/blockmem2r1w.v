//======================================================================
//
// blockmem2r1w.v
// --------------
// Synchronous block memory with two read ports and one write port.
// The data size is the same for both read and write operations.
//
// The memory is used in the modexp core.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2014, Secworks Sweden AB
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

module blockmem2r1w(
                    input wire           clk,

                    input wire  [07 : 0] read_addr0,
                    output wire [31 : 0] read_data0,

                    input wire  [07 : 0] read_addr1,
                    output wire [31 : 0] read_data1,

                    input wire           wr,
                    input wire  [07 : 0] write_addr,
                    input wire  [31 : 0] write_data
                   );

  reg [31 : 0] mem [0 : 255];
  reg [31 : 0] tmp_read_data0;
  reg [31 : 0] tmp_read_data1;

  assign read_data0 = tmp_read_data0;
  assign read_data1 = tmp_read_data1;

  always @ (posedge clk)
    begin : reg_mem
      if (wr)
        mem[write_addr] <= write_data;

      tmp_read_data0 <= mem[read_addr0];
      tmp_read_data1 <= mem[read_addr1];
    end

endmodule // blockmem2r1w

//======================================================================
// EOF blockmem2r1w.v
//======================================================================

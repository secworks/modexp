//======================================================================
//
// residue.v
// ---------
// Modulus 2**2N residue calculator for montgomery calculations.
//
// m_residue_2_2N_array( N, M, Nr)
//   Nr = 00...01 ; Nr = 1 == 2**(2N-2N) 
//   for (int i = 0; i < 2 * N; i++)
//     Nr = Nr shift left 1
//     if (Nr less than M) continue;
//     Nr = Nr - M
// return Nr
//
//
//
// Author: Peter Magnusson
// Copyright (c) 2015 Assured AB
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

module residue(
  input wire clk,
  input wire reset_n,

  input wire  calculate,
  output wire ready,

  input wire  [07 : 0] nn,
  input wire  [07 : 0] length,

  output wire [07 : 0] opa_rd_addr,
  input wire  [31 : 0] opa_rd_data,
  output wire [07 : 0] opa_wr_addr,
  output wire [31 : 0] opa_wr_data,
  output wire          opa_wr_we,

  output wire [07 : 0] opm_addr,
  input wire  [31 : 0] opm_data

);

//----------------------------------------------------------------
// Internal constant and parameter definitions.
//----------------------------------------------------------------


localparam CTRL_IDLE          = 3'h0;
localparam CTRL_INIT          = 3'h1;
localparam CTRL_INIT_STALL    = 3'h2;
localparam CTRL_SHL           = 3'h3;
localparam CTRL_SHL_STALL     = 3'h4;
localparam CTRL_COMPARE       = 3'h5;
localparam CTRL_COMPARE_STALL = 3'h6;
localparam CTRL_SUB           = 3'h7;
localparam CTRL_SUB_STALL     = 3'h8;
localparam CTRL_LOOP          = 3'h9;

//----------------------------------------------------------------
// Registers including update variables and write enable.
//----------------------------------------------------------------

reg [07 : 0] opa_rd_addr_reg;
reg [07 : 0] opa_wr_addr_reg;
reg [31 : 0] opa_wr_data_reg;
reg          opa_wr_we_reg;
reg [07 : 0] opm_addr_reg;
reg          ready_reg;
reg          ready_new;
reg          ready_we;
reg [02 : 0] residue_ctrl_reg;
reg [02 : 0] residue_ctrl_new;
reg          residue_ctrl_we;
reg          reset_word_index;
reg          reset_n_counter;
reg [07 : 0] word_index;

//----------------------------------------------------------------
// Concurrent connectivity for ports etc.
//----------------------------------------------------------------
assign opa_rd_addr = opa_rd_addr_reg;
assign opa_wr_addr = opa_wr_addr_reg;
assign opa_wr_data = opa_wr_data_reg;
assign opm_addr    = opm_addr_reg;
assign ready       = ready_reg;

always @*
  begin : process_1_to_2n
  end

always @*
  begin : word_index_process
  end

//----------------------------------------------------------------
// residue
//
// Control FSM for residue
//----------------------------------------------------------------
always @*
  begin : residue_ctrl
    ready_new = 1'b0;
    ready_we  = 1'b0;
    residue_ctrl_new = CTRL_IDLE;
    residue_ctrl_we  = 1'b0;
    reset_word_index = 1'b0;
    reset_n_counter  = 1'b0;

    case (residue_ctrl_reg)
      CTRL_IDLE:
        if (calculate)
          begin
            ready_new = 1'b0;
            ready_we  = 1'b1;
            residue_ctrl_new = CTRL_INIT;
            residue_ctrl_we  = 1'b1;
            reset_word_index = 1'b1;
          end

      CTRL_INIT:
        if (word_index == 8'h0)
          begin
            residue_ctrl_new = CTRL_INIT_STALL;
            residue_ctrl_we  = 1'b1;
          end

      CTRL_INIT_STALL:
        begin
          reset_word_index = 1'b1;
          reset_n_counter  = 1'b1;
          residue_ctrl_new = CTRL_COMPARE;
          residue_ctrl_we  = 1'b1;
        end

      CTRL_COMPARE:
        begin
        end

      CTRL_COMPARE_STALL:
        begin
        end

      CTRL_SUB:
        begin
        end

      CTRL_SUB_STALL:
        begin
        end

      CTRL_SHL:
        begin
        end

      CTRL_SHL_STALL:
        begin
        end

      CTRL_LOOP:
        begin
        end

    endcase
  end

endmodule



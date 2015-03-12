//======================================================================
//
// montprod.v
// ---------
// Montgomery product calculator for the modular exponentiantion core.
//
//
// Author: Peter Magnusson, Joachim Strombergson
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

module montprod(
                input wire           clk,
                input wire           reset_n,

                input wire           calculate,
                output wire          ready,

                input   [7 : 0]      length,

                output wire [7 : 0]  opa_addr,
                input wire [31 : 0]  opa_data,

                output wire [7 : 0]  opb_addr,
                input wire [31 : 0]  opb_data,

                output wire [7 : 0]  opm_addr,
                input wire [31 : 0]  opm_data,

                output wire [7 : 0]  result_addr,
                output wire [31 : 0] result_data,
                output wire          result_we
               );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter CTRL_IDLE  = 3'h0;
  parameter CTRL_START = 3'h1;
  parameter CTRL_INIT  = 3'h2;
  parameter CTRL_DONE  = 3'h6;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [31 : 0] tmp_mem [0 : 255];
  reg [07 : 0] tmp_mem_rd_addr;
  reg [31 : 0] tmp_mem_rd_data;
  reg [07 : 0] tmp_mem_wr_addr;
  reg [31 : 0] tmp_mem_wr_data;
  reg          tmp_mem_we;

  reg [07 : 0] opa_addr_reg;
  reg [07 : 0] opb_addr_reg;
  reg [07 : 0] opm_addr_reg;

  reg [07 : 0] result_addr_reg;
  reg [31 : 0] result_data_reg;
  reg          result_we_reg;

  reg          ready_reg;
  reg          ready_new;
  reg          ready_we;

  reg [2 : 0]  montprod_ctrl_reg;
  reg [2 : 0]  montprod_ctrl_new;
  reg          montprod_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign opa_addr    = opa_addr_reg;
  assign opb_addr    = opb_addr_reg;
  assign opm_addr    = opm_addr_reg;

  assign result_addr = result_addr_reg;
  assign result_data = result_data_reg;
  assign result_we   = result_we_reg;

  assign ready       = ready_reg;


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with asynchronous
  // active low reset. All registers have write enable.
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin : reg_update
      if (!reset_n)
        begin
          ready_reg         <= 1'b0;
          montprod_ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          tmp_mem_rd_data <= tmp_mem[tmp_mem_rd_addr];

          if (tmp_mem_we)
            tmp_mem[tmp_mem_wr_addr] <= tmp_mem_wr_data;

          if (ready_we)
            ready_reg <= ready_new;

          if (montprod_ctrl_we)
              montprod_ctrl_reg <= montprod_ctrl_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // prodcalc
  //----------------------------------------------------------------
  always @*
    begin : prodcalc
      tmp_mem_rd_addr = 8'h00;
      tmp_mem_wr_addr = 8'h00;
      tmp_mem_wr_data = 32'h00000000;
      tmp_mem_we      = 1'b0;
    end // prodcalc


  //----------------------------------------------------------------
  // montprod_ctrl
  //
  // Control FSM for the montgomery product calculator.
  //----------------------------------------------------------------
  always @*
    begin : montprod_ctrl
      ready_new = 1'b0;
      ready_we  = 1'b0;

      case (montprod_ctrl_reg)
        CTRL_IDLE:
          begin
            if (calculate)
              begin
                ready_new = 1'b0;
                ready_we  = 1'b1;
              end
          end

        CTRL_DONE:
          begin
            ready_new = 1'b1;
            ready_we  = 1'b1;
          end

        default:
          begin
          end

      endcase // case (montprod_ctrl_reg)
    end // montprod_ctrl

endmodule // montprod

//======================================================================
// EOF montprod.v
//======================================================================

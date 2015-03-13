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
  parameter CTRL_IDLE         = 3'h0;
  parameter CTRL_INIT_S       = 3'h1;
  parameter CTRL_LOOP_INIT    = 3'h2;
  parameter CTRL_LOOP_ITER    = 3'h3; //calculate q = (s - b * A) & 1;. Also abort loop if done. 
  parameter CTRL_L_CALC_SM    = 3'h4; //s = (s + q*M + b*A) >>> 1;, if(q==1) S+= M. Takes (1..length) cycles.
  parameter CTRL_L_CALC_SA    = 3'h5; //s = (s + q*M + b*A) >>> 1;, if(b==1) S+= A. Takes (1..length) cycles.
  parameter CTRL_L_CALC_SDIV2 = 3'h6; //s = (s + q*M + b*A) >>> 1; s>>=1. Takes (1..length) cycles.
  parameter CTRL_DONE         = 3'h7; 

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

  reg [31 : 0] A_mem [0 : 255];
  reg [31 : 0] B_mem [0 : 255];
  reg [31 : 0] M_mem [0 : 255];

  reg [31 : 0] s_mem [0 : 255];
  reg [31 : 0] s_mem_new;
  reg          s_mem_we;

  reg          q; //q = (s - b * A) & 1
  reg          b; //b: bit of B
  
  reg [12 : 0] loop_counter;
  reg [12 : 0] loop_counter_new;
  reg [12 : 0] loop_counter_dec;
  reg [07 : 0] B_word_index; //loop counter as a word index
  reg [04 : 0] B_bit_index; //loop counter as a bit index

  reg [07 : 0] word_index;
  reg [07 : 0] word_index_new;
  reg [07 : 0] word_index_dec;


  reg [32 : 0] add;
  reg [32 : 0] add_argument1;
  reg [32 : 0] add_argument2;
  reg          add_carry_in;

  reg          reset_word_index;

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
          loop_counter      <= 13'h0;
          word_index        <= 8'h0;
          add_carry_in      <= 1'b0;
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

         if (s_mem_we) 
           s_mem[word_index] <= s_mem_new;

         word_index <= word_index_new;
         loop_counter <= loop_counter_new;
         add_carry_in <= add[32];

      end
    end // reg_update


  //----------------------------------------------------------------
  // prodcalc
  //----------------------------------------------------------------
  always @*
    begin : prodcalc
      tmp_mem_rd_addr  = 8'h00;
      tmp_mem_wr_addr  = 8'h00;
      tmp_mem_wr_data  = 32'h00000000;
      tmp_mem_we       = 1'b0;
      B_word_index     = loop_counter[12:5];
      B_bit_index      = 31 - loop_counter[4:0];
      b                = B_mem[ B_word_index ][ B_bit_index ]; 
      q                = s_mem[ length-1 ][0] ^ (A_mem[ length-1 ][0] & b);
      word_index_dec   = word_index - 1;
      loop_counter_dec = loop_counter - 1;

      case (montprod_ctrl_reg)
        CTRL_LOOP_INIT:
          loop_counter_new = (length*32)-1;
        CTRL_LOOP_ITER:
          loop_counter_new = loop_counter_dec; 
        default:
          loop_counter_new = loop_counter;
      endcase
      
      if (reset_word_index == 1'b1)
          word_index_new = length - 1;
      else
          word_index_new = word_index - 1;
 

      add_argument1[32] = 1'b0;
      add_argument2[32] = 1'b0;

      if ( add_carry_in == 1'b1 )
        add = add_argument1 + add_argument2 + 1;
      else
        add = add_argument1 + add_argument2 + 0;

      s_mem_new = add[31 : 0];
      

      case (montprod_ctrl_reg)
        CTRL_INIT_S:
          begin
            // write 0 to initilize s.
            add_argument1[31:0] = 32'b0;
            add_argument2[31:0] = 32'b0;
          end
        CTRL_L_CALC_SM:
          begin
            add_argument1[31:0] = s_mem[word_index];
            add_argument2[31:0] = A_mem[word_index];
          end
        CTRL_L_CALC_SA:
          begin
            add_argument1[31:0] = s_mem[word_index];
            add_argument2[31:0] = A_mem[word_index];
          end
        default:
          begin
            // output is not directly used, but it is important that carry out will be zero.
            add_argument1[31:0] = 32'b0;
            add_argument2[31:0] = 32'b0;
          end
      endcase
        

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
      montprod_ctrl_we = 1'b0;
      reset_word_index = 1'b0;
      s_mem_we = 1'b0;

      case (montprod_ctrl_reg)
        CTRL_IDLE:
          begin
            if (calculate)
              begin
                ready_new = 1'b0;
                ready_we  = 1'b1;
                montprod_ctrl_new = CTRL_INIT_S;
                montprod_ctrl_we = 1'b1;
                reset_word_index = 1'b1;
              end
          end

        CTRL_INIT_S:
          begin
            if (word_index == 0)
              begin
                 montprod_ctrl_new = CTRL_LOOP_INIT;
                 montprod_ctrl_we = 1'b1;
              end
          end


        CTRL_LOOP_INIT:
          begin
            montprod_ctrl_new = CTRL_LOOP_ITER;
          end

        CTRL_LOOP_ITER: //calculate q = (s - b * A) & 1;. Also abort loop if done. 
          begin
            if (loop_counter == 0)
              begin
                montprod_ctrl_new = CTRL_DONE;
                montprod_ctrl_we = 1'b1;
              end
            else
              begin
                montprod_ctrl_new = CTRL_L_CALC_SM;
                montprod_ctrl_we  = 1'b1;
                reset_word_index  = 1'b1;
              end
          end

        CTRL_L_CALC_SM:
          begin
            s_mem_we = 1'b1;
            if (word_index == 0)
              begin
                montprod_ctrl_new = CTRL_L_CALC_SA;
                montprod_ctrl_we  = 1'b1;
                reset_word_index  = 1'b1;
              end
          end


        CTRL_L_CALC_SA:
          begin
            s_mem_we = 1'b1;
            if (word_index == 0)
              begin
                montprod_ctrl_new = CTRL_L_CALC_SDIV2;
                montprod_ctrl_we = 1'b1;
                reset_word_index = 1'b1;
              end
          end


        CTRL_L_CALC_SDIV2:
          begin
            s_mem_we = 1'b1;
            if (word_index == 8'h0)
              begin
                montprod_ctrl_new = CTRL_LOOP_ITER; //loop
                montprod_ctrl_we = 1'b1;
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

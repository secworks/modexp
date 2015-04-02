//======================================================================
//
// modexp.v
// --------
// Modular exponentiation core for implementing public key algorithms
// such as RSA, DH, ElGamal etc.
//
// The core calculates the following function:
//
//   C = M ** e mod N
//
//   M is a message with a length of n bits
//   e is the exponent with a length of at most 32 bits
//   N is the modulus  with a length of n bits
//   n is can be 32 and up to and including 8192 bits in steps
//   of 32 bits.
//
// The core has a 32-bit memory like interface, but provides
// status signals to inform the system that a given operation
// has is done. Additionally, any errors will also be asserted.
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

module modexp(
              input wire           clk,
              input wire           reset_n,

              input wire           cs,
              input wire           we,

              input wire  [11 : 0] address,
              input wire  [31 : 0] write_data,
              output wire [31 : 0] read_data
             );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam GENERAL_PREFIX      = 4'h0;
  localparam ADDR_NAME0          = 8'h00;
  localparam ADDR_NAME1          = 8'h01;
  localparam ADDR_VERSION        = 8'h02;

  localparam ADDR_MODSIZE        = 8'h10;
  localparam ADDR_EXPONENT       = 8'h20;

  localparam MODULUS_PREFIX      = 4'h1;
  localparam ADDR_MODULUS_START  = 8'h00;
  localparam ADDR_MODULUS_END    = 8'hff;

  localparam EXPONENT_PREFIX     = 4'h2;
  localparam ADDR_EXPONENT_START = 8'h00;
  localparam ADDR_EXPONENT_END   = 8'hff;

  localparam MESSAGE_PREFIX      = 4'h3;
  localparam MESSAGE_START       = 8'h00;
  localparam MESSAGE_END         = 8'hff;

  localparam RESULT_PREFIX       = 4'h4;
  localparam RESULT_START        = 8'h00;
  localparam RESULT_END          = 8'hff;

  localparam DEFAULT_MODLENGTH   = 8'h80;
  localparam DEFAULT_EXPLENGTH   = 8'h80;

  localparam MONTPROD_SELECT_ONE_NR = 3'h0;
  localparam MONTPROD_SELECT_X_NR   = 3'h1;
  localparam MONTPROD_SELECT_Z_P    = 3'h2;
  localparam MONTPROD_SELECT_P_P    = 3'h3;
  localparam MONTPROD_SELECT_ONE_Z  = 3'h4;

  localparam CTRL_IDLE           = 3'h0;
  localparam CTRL_RESIDUE        = 3'h1;
  localparam CTRL_CALCULATE_Z0   = 3'h2;
  localparam CTRL_CALCULATE_P0   = 3'h3;
  localparam CTRL_ITERATE        = 3'h4;
  localparam CTRL_CALCULATE_ZN   = 3'h5;
  localparam CTRL_DONE           = 3'h6;

  localparam CORE_NAME0          = 32'h72736120; // "rsa "
  localparam CORE_NAME1          = 32'h38313932; // "8192"
  localparam CORE_VERSION        = 32'h302e3031; // "0.01"


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [07 : 0]  modulus_mem_int_rd_addr;
  wire [31 : 0] modulus_mem_int_rd_data;
  wire [31 : 0] modulus_mem_api_rd_data;
  reg           modulus_mem_api_we;

  reg [07 : 0]  message_mem_int_rd_addr;
  wire [31 : 0] message_mem_int_rd_data;
  wire [31 : 0] message_mem_api_rd_data;
  reg           message_mem_api_we;

  reg [07 : 0]  exponent_mem_int_rd_addr;
  wire [31 : 0] exponent_mem_int_rd_data;
  wire [31 : 0] exponent_mem_api_rd_data;
  reg           exponent_mem_api_we;

  wire [31 : 0] result_mem_api_rd_data;
  reg [07 : 0]  result_mem_int_wr_addr;
  wire [31 : 0] result_mem_int_wr_data;
  reg           result_mem_int_we;

  reg          residue_calculator_start; //TODO not implemented yet
  reg          residue_calculator_ready; //TODO not implemented yet

  reg [31 : 0] residue_mem [0 : 255];
  reg [07 : 0] residue_mem_rd_addr;
  reg [31 : 0] residue_mem_rd_data;
  reg [07 : 0] residue_mem_wr_addr;
  reg [31 : 0] residue_mem_wr_data;
  reg          residue_mem_we;

  reg [31 : 0] p_mem [0 : 255];
  reg [31 : 0] p_mem_rd_data;
  reg [07 : 0] p_mem_wr_addr;
  reg [31 : 0] p_mem_wr_data;
  reg          p_mem_we;

  reg [31 : 0] tmp2_mem [0 : 255];
  reg [31 : 0] tmp2_mem_rd_data;
  reg [07 : 0] tmp2_mem_wr_addr;
  reg [31 : 0] tmp2_mem_wr_data;
  reg          tmp2_mem_we;

  reg [07 : 0] length_reg; //TODO not implemented yet
  reg [07 : 0] length_m1;  //TODO not implemented yet

  reg          start_reg;
  reg          start_new;
  reg          start_we;

  reg          ready_reg;
  reg          ready_new;
  reg          ready_we;

  reg [2 : 0]  montprod_select_reg;
  reg [2 : 0]  montprod_select_new;
  reg          montprod_select_we;

  reg [2 : 0]  modexp_ctrl_reg;
  reg [2 : 0]  modexp_ctrl_new;
  reg          modexp_ctrl_we;

  reg [31 : 0] one;
  reg [31 : 0] one_new;

  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [31 : 0]  tmp_read_data;
  reg           tmp_error;

  reg           montprod_calc;
  wire          montprod_ready;
  reg [07 : 0]  montprod_length;

  wire [07 : 0] montprod_opa_addr;
  reg [31 : 0]  montprod_opa_data;

  wire [07 : 0] montprod_opb_addr;
  reg [31 : 0]  montprod_opb_data;

  wire [07 : 0] montprod_opm_addr;
  reg [31 : 0]  montprod_opm_data;

  wire [07 : 0] montprod_result_addr;
  wire [31 : 0] montprod_result_data;
  wire          montprod_result_we;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign read_data = tmp_read_data;


  //----------------------------------------------------------------
  // core instantiations.
  //----------------------------------------------------------------
  montprod montprod_inst(
                         .clk(clk),
                         .reset_n(reset_n),

                         .calculate(montprod_calc),
                         .ready(montprod_ready),

                         .length(montprod_length),

                         .opa_addr(montprod_opa_addr),
                         .opa_data(montprod_opa_data),

                         .opb_addr(montprod_opb_addr),
                         .opb_data(montprod_opb_data),

                         .opm_addr(montprod_opm_addr),
                         .opm_data(message_mem_int_rd_data),

                         .result_addr(montprod_result_addr),
                         .result_data(montprod_result_data),
                         .result_we(montprod_result_we)
                        );


  blockmem2r1w modulus_mem(
                           .clk(clk),
                           .read_addr0(modulus_mem_int_rd_addr),
                           .read_data0(modulus_mem_int_rd_data),
                           .read_addr1(address[7 : 0]),
                           .read_data1(modulus_mem_api_rd_data),
                           .wr(modulus_mem_api_we),
                           .write_addr(address[7 : 0]),
                           .write_data(write_data)
                          );


  blockmem2r1w message_mem(
                           .clk(clk),
                           .read_addr0(message_mem_int_rd_addr),
                           .read_data0(message_mem_int_rd_data),
                           .read_addr1(address[7 : 0]),
                           .read_data1(message_mem_api_rd_data),
                           .wr(message_mem_api_we),
                           .write_addr(address[7 : 0]),
                           .write_data(write_data)
                          );


  blockmem2r1w exponent_mem(
                           .clk(clk),
                           .read_addr0(exponent_mem_int_rd_addr),
                           .read_data0(exponent_mem_int_rd_data),
                           .read_addr1(address[7 : 0]),
                           .read_data1(exponent_mem_api_rd_data),
                           .wr(exponent_mem_api_we),
                           .write_addr(address[7 : 0]),
                           .write_data(write_data)
                           );


  blockmem1r1w result_mem(
                          .clk(clk),
                          .read_addr(address[7 : 0]),
                          .read_data(result_mem_api_rd_data),
                          .wr(result_mem_int_we),
                          .write_addr(result_mem_int_wr_addr),
                          .write_data(result_mem_int_wr_data)
                         );


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with asynchronous
  // active low reset. All registers have write enable.
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          ready_reg           <= 1'b1;
          montprod_select_reg <= MONTPROD_SELECT_ONE_NR;
          modexp_ctrl_reg     <= CTRL_IDLE;
          one                 <= 32'h0;
        end
      else
        begin
          if (ready_we)
            ready_reg <= ready_new;

          if (montprod_select_we)
            montprod_select_reg <= montprod_select_new;

          if (modexp_ctrl_we)
            modexp_ctrl_reg <= modexp_ctrl_new;

          one <= one_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // api
  //
  // The interface command decoding logic.
  //----------------------------------------------------------------
  always @*
    begin : api
      modulus_mem_api_we  = 1'b0;
      exponent_mem_api_we = 1'b0;
      message_mem_api_we  = 1'b0;
      tmp_read_data       = 32'h00000000;

      if (cs)
        begin
          case (address[11 : 8])
            GENERAL_PREFIX:
              begin
//                if (we)
//                  begin
//                    case (address)
//                      // Write operations.
//                      ADDR_MODSIZE:
//                        begin
//                          modsize_we  = 1;
//                        end
//
//                      ADDR_EXPONENT:
//                        begin
//                          exponent_we = 1;
//                        end
//
//                      default:
//                        begin
//                          tmp_error = 1;
//                        end
//                    endcase // case (addr)
//                  end // if (write_read)
//                else
//                  begin
//                    case (address)
//                      // Read operations.
//                      ADDR_NAME0:
//                        begin
//                          tmp_read_data = CORE_NAME0;
//                        end
//
//                      ADDR_NAME1:
//                        begin
//                          tmp_read_data = CORE_NAME1;
//                        end
//
//                      ADDR_VERSION:
//                        begin
//                          tmp_read_data = CORE_VERSION;
//                        end
//
//                      ADDR_MODSIZE:
//                        begin
//                          tmp_read_data = {28'h0000000, modsize_reg};
//                        end
//
//                      default:
//                        begin
//                          tmp_error = 1;
//                        end
//                    endcase // case (addr)
//                  end
              end

            MODULUS_PREFIX:
              begin
                if (we)
                  begin
                    modulus_mem_api_we = 1'b1;
                  end
                else
                  begin
                    tmp_read_data = modulus_mem_api_rd_data;
                  end
              end

            EXPONENT_PREFIX:
              begin
                if (we)
                  begin
                    exponent_mem_api_we = 1'b1;
                  end
                else
                  begin
                    tmp_read_data = exponent_mem_api_rd_data;
                  end
              end

            MESSAGE_PREFIX:
              begin
                if (we)
                  begin
                    message_mem_api_we = 1'b1;
                  end
                else
                  begin
                    tmp_read_data = message_mem_api_rd_data;
                  end
              end

            RESULT_PREFIX:
              begin
                tmp_read_data = result_mem_api_rd_data;
              end

//            RESULT_PREFIX:
//              begin
//                if (we)
//                  begin
//                    modulus_mem_api_we = 1'b1;
//                  end
//                else
//                  begin
//                    tmp_read_data = modulus_mem_int_rd_data;
//                  end
//              end

            default:
              begin

              end
          endcase // case (address[11 : 8])
        end // if (cs)
    end // api


  //----------------------------------------------------------------
  // montprod_op_select
  //
  // Select operands used during montprod calculations depending
  // on what operation we want to do
  //----------------------------------------------------------------
  always @*
    begin : montprod_op_select
      message_mem_int_rd_addr  = montprod_opa_addr;

      residue_mem_rd_addr      = montprod_opb_addr;

      modulus_mem_int_rd_addr  = montprod_opm_addr;
      //exponent_mem_int_rd_addr = 8'h00;

      montprod_opa_data        = 32'h00000000;
      montprod_opb_data        = 32'h00000000;

      if (montprod_opa_addr == length_m1) 
        one_new = 32'h00000001;
      else
        one_new = 32'h00000000;

      case (montprod_select_reg)
        MONTPROD_SELECT_ONE_NR:
          begin
            montprod_opa_data       = one;
            montprod_opb_data       = residue_mem_rd_data;
          end

        MONTPROD_SELECT_X_NR:
          begin
            montprod_opa_data       = message_mem_int_rd_data;
            montprod_opb_data       = residue_mem_rd_data;
          end

          //TODO more states
        default:
          begin
          end
      endcase // case (montprod_selcect_reg)
    end


  //----------------------------------------------------------------
  // modexp_ctrl
  //
  // Control FSM logic needed to perform the modexp operation.
  //----------------------------------------------------------------
  always @*
    begin
      ready_new           = 0;
      ready_we            = 0;
      montprod_select_new = MONTPROD_SELECT_ONE_NR;
      montprod_select_we  = 0;
      modexp_ctrl_new     = CTRL_IDLE;
      modexp_ctrl_we      = 0;

      residue_calculator_start = 1'b0;

      case (modexp_ctrl_reg)
        CTRL_IDLE:
          begin
            ready_new           = 0;
            ready_we            = 1;
            if (start_reg == 1'b1)
              begin
                modexp_ctrl_new = CTRL_RESIDUE;
                modexp_ctrl_we  = 1;
                residue_calculator_start = 1'b0;
              end
          end

        CTRL_RESIDUE:
          begin
            if (residue_calculator_ready == 1'b1)
              begin
                montprod_select_new = MONTPROD_SELECT_ONE_NR;
                montprod_select_we  = 0;
                modexp_ctrl_new = CTRL_CALCULATE_Z0;
                modexp_ctrl_we  = 1;
              end
          end

        CTRL_CALCULATE_Z0:
          begin

          end

        CTRL_CALCULATE_P0:
          begin

          end

        CTRL_ITERATE:
          begin

          end

        CTRL_CALCULATE_ZN:
          begin

          end

        CTRL_DONE:
          begin
            ready_new           = 1;
            ready_we            = 1;
            modexp_ctrl_new     = CTRL_IDLE;
            modexp_ctrl_we      = 1;
          end

        default:
          begin
          end

      endcase // case (modexp_ctrl_reg)
    end

endmodule // modexp

//======================================================================
// EOF modexp.v
//======================================================================

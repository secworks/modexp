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
// Author: Joachim Strombergson, Peter Magnusson.
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

  localparam ADDR_CTRL           = 8'h08;
  localparam CTRL_INIT_BIT       = 0;
  localparam CTRL_NEXT_BIT       = 1;

  localparam ADDR_STATUS         = 8'h09;
  localparam STATUS_READY_BIT    = 0;

  localparam ADDR_MODULUS_LENGTH  = 8'h20;
  localparam ADDR_EXPONENT_LENGTH = 8'h21;
  localparam ADDR_LENGTH          = 8'h22; // Should be deprecated.


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
  localparam MONTPROD_SELECT_Z_ONE  = 3'h4;

  localparam MONTPROD_DEST_Z        = 2'b00;
  localparam MONTPROD_DEST_P        = 2'b01;
  localparam MONTPROD_DEST_NOWHERE  = 2'b10;

  localparam CTRL_IDLE           = 4'h0;
  localparam CTRL_RESIDUE        = 4'h1;
  localparam CTRL_CALCULATE_Z0   = 4'h2;
  localparam CTRL_CALCULATE_P0   = 4'h3;
  localparam CTRL_ITERATE        = 4'h4;
  localparam CTRL_ITERATE_Z_P    = 4'h5;
  localparam CTRL_ITERATE_P_P    = 4'h6;
  localparam CTRL_ITERATE_END    = 4'h7;
  localparam CTRL_CALCULATE_ZN   = 4'h8;
  localparam CTRL_DONE           = 4'h9;

  localparam EXPONATION_MODE_SECRET_SECURE = 1'b0;
  localparam EXPONATION_MODE_PUBLIC_FAST   = 1'b1; //for rsa, c=M^65537 etc, there is no need to slow down to hide the exponent


  localparam CORE_NAME0          = 32'h6d6f6465; // "mode"
  localparam CORE_NAME1          = 32'h78702020; // "xp  "
  localparam CORE_VERSION        = 32'h302e3031; // "0.01"


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [07 : 0] exponent_length_reg;
  reg [07 : 0] exponent_length_new;
  reg          exponent_length_we;

  reg [07 : 0] modulus_length_reg;
  reg [07 : 0] modulus_length_new;
  reg          modulus_length_we;

  reg [07 : 0] length_reg;
  reg [07 : 0] length_new;
  reg [07 : 0] length_m1_reg;
  reg [07 : 0] length_m1_new;
  reg          length_we;

  reg          start_reg;
  reg          start_new;
  reg          start_we;
  reg          clear_start;

  reg          ready_reg;
  reg          ready_new;
  reg          ready_we;

  reg [2 : 0]  montprod_select_reg;
  reg [2 : 0]  montprod_select_new;
  reg          montprod_select_we;
  reg [1 : 0]  montprod_dest_reg;
  reg [1 : 0]  montprod_dest_new;
  reg          montprod_dest_we;

  reg [3 : 0]  modexp_ctrl_reg;
  reg [3 : 0]  modexp_ctrl_new;
  reg          modexp_ctrl_we;

  reg [31 : 0] one_reg;
  reg [31 : 0] one_new;
  reg [31 : 0] b_one_reg;
  reg [31 : 0] b_one_new;

  reg [12 : 0] loop_counter_reg;
  reg [12 : 0] loop_counter_new;
  reg          loop_counter_we;

  reg [07 : 0] E_word_index;
  reg [04 : 0] E_bit_index;
  reg          last_iteration;

  reg          ei_reg;
  reg          ei_new;
  reg          ei_we;

  reg          exponation_mode_reg;
  reg          exponation_mode_new;
  reg          exponation_mode_we;


  //----------------------------------------------------------------
  // Wires.
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
  reg  [07 : 0] result_mem_int_rd_addr;
  wire [31 : 0] result_mem_int_rd_data;
  reg  [07 : 0] result_mem_int_wr_addr;
  reg  [31 : 0] result_mem_int_wr_data;
  reg           result_mem_int_we;

  reg  [07 : 0] p_mem_rd0_addr;
  wire [31 : 0] p_mem_rd0_data;
  reg  [07 : 0] p_mem_rd1_addr;
  wire [31 : 0] p_mem_rd1_data;
  reg  [07 : 0] p_mem_wr_addr;
  reg  [31 : 0] p_mem_wr_data;
  reg           p_mem_we;

  reg [31 : 0]  tmp_read_data;
  //reg           tmp_error;

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

  reg            residue_calculate;
  wire           residue_ready;
  reg [14 : 0]   residue_nn;
  reg  [07 : 0]  residue_length;
  wire [07 : 0]  residue_opa_rd_addr;
  wire [31 : 0]  residue_opa_rd_data;
  wire [07 : 0]  residue_opa_wr_addr;
  wire [31 : 0]  residue_opa_wr_data;
  wire           residue_opa_wr_we;
  wire [07 : 0]  residue_opm_addr;
  reg [31 : 0]   residue_opm_data;

  reg  [07 : 0] residue_mem_montprod_read_addr;
  wire [31 : 0] residue_mem_montprod_read_data;

  reg           residue_valid_reg;
  reg           residue_valid_new;
  reg           invalidate_residue;
  reg           residue_valid_int_validated;

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
                         .opm_data(montprod_opm_data),

                         .result_addr(montprod_result_addr),
                         .result_data(montprod_result_data),
                         .result_we(montprod_result_we)
                        );


  residue residue_inst(
                     .clk(clk),
                     .reset_n(reset_n),
                     .calculate(residue_calculate),
                     .ready(residue_ready),
                     .nn(residue_nn),
                     .length(residue_length),
                     .opa_rd_addr(residue_opa_rd_addr),
                     .opa_rd_data(residue_opa_rd_data),
                     .opa_wr_addr(residue_opa_wr_addr),
                     .opa_wr_data(residue_opa_wr_data),
                     .opa_wr_we(residue_opa_wr_we),
                     .opm_addr(residue_opm_addr),
                     .opm_data(residue_opm_data)
                    );

  blockmem2r1w residue_mem(
                           .clk(clk),
                           .read_addr0(residue_opa_rd_addr),
                           .read_data0(residue_opa_rd_data),
                           .read_addr1(residue_mem_montprod_read_addr),
                           .read_data1(residue_mem_montprod_read_data),
                           .wr(residue_opa_wr_we),
                           .write_addr(residue_opa_wr_addr),
                           .write_data(residue_opa_wr_data)
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


  blockmem2r1w result_mem(
                          .clk(clk),
                          .read_addr0(result_mem_int_rd_addr[7 : 0]),
                          .read_data0(result_mem_int_rd_data),
                          .read_addr1(address[7 : 0]),
                          .read_data1(result_mem_api_rd_data),
                          .wr(result_mem_int_we),
                          .write_addr(result_mem_int_wr_addr),
                          .write_data(result_mem_int_wr_data)
                         );

  blockmem2r1w p_mem(
                     .clk(clk),
                     .read_addr0(p_mem_rd0_addr),
                     .read_data0(p_mem_rd0_data),
                     .read_addr1(p_mem_rd1_addr),
                     .read_data1(p_mem_rd1_data),
                     .wr(p_mem_we),
                     .write_addr(p_mem_wr_addr),
                     .write_data(p_mem_wr_data)
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
          exponent_length_reg <= DEFAULT_EXPLENGTH;
          modulus_length_reg  <= DEFAULT_MODLENGTH;
          start_reg           <= 1'b0;
          ready_reg           <= 1'b1;
          montprod_select_reg <= MONTPROD_SELECT_ONE_NR;
          montprod_dest_reg   <= MONTPROD_DEST_NOWHERE;
          modexp_ctrl_reg     <= CTRL_IDLE;
          one_reg             <= 32'h0;
          b_one_reg           <= 32'h0;
          length_reg          <= 8'h0;
          length_m1_reg       <= 8'h0;
          loop_counter_reg    <= 13'b0;
          ei_reg              <= 1'b0;
          residue_valid_reg   <= 1'b0;
          exponation_mode_reg <= EXPONATION_MODE_SECRET_SECURE;
        end
      else
        begin
          one_reg <= one_new;
          b_one_reg <= b_one_new;
          residue_valid_reg <= residue_valid_new;

          if (exponent_length_we)
            exponent_length_reg <= exponent_length_new;

          if (modulus_length_we)
            modulus_length_reg <= modulus_length_new;

          if (start_we)
            start_reg <= start_new;

          if (ready_we)
            ready_reg <= ready_new;

          if (montprod_select_we)
            montprod_select_reg <= montprod_select_new;

          if (montprod_dest_we)
            montprod_dest_reg <= montprod_dest_new;

          if (modexp_ctrl_we)
            modexp_ctrl_reg <= modexp_ctrl_new;

          if (length_we)
            begin
              length_reg    <= length_new;
              length_m1_reg <= length_m1_new;
            end

          if (loop_counter_we)
            loop_counter_reg <= loop_counter_new;

          if (ei_we)
            ei_reg <= ei_new;

          if (exponation_mode_we)
            exponation_mode_reg <= exponation_mode_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // api
  //
  // The interface command decoding logic.
  //----------------------------------------------------------------
  always @*
    begin : api
      modulus_length_we   = 1'b0;
      exponent_length_we  = 1'b0;
      start_new           = 1'b0;
      start_we            = 1'b0;
      modulus_mem_api_we  = 1'b0;
      exponent_mem_api_we = 1'b0;
      message_mem_api_we  = 1'b0;
      length_we           = 1'b0;
      invalidate_residue  = 1'b0;

      //TODO: Add API code to enable fast exponation for working with public exponents.
      exponation_mode_we  = 1'b0;

      exponation_mode_new = EXPONATION_MODE_SECRET_SECURE;
      modulus_length_new  = write_data[7 : 0];
      exponent_length_new = write_data[7 : 0];
      length_new          = write_data[7 : 0];
      length_m1_new       = write_data[7 : 0] - 8'h1;

      tmp_read_data       = 32'h00000000;

      // We need to be able to clear start bit after we have
      // started a modexp operation.
      if (clear_start)
        begin
          start_new = 1'b0;
          start_we  = 1'b1;
        end

      if (cs)
        begin
          case (address[11 : 8])
            GENERAL_PREFIX:
              begin
                if (we)
                  begin
                    case (address[7 : 0])
                      ADDR_CTRL:
                        begin
                          start_new = write_data[0];
                          start_we  = 1'b1;
                        end

                      ADDR_LENGTH:
                        begin
                          length_we = 1'b1;
                        end

                      ADDR_MODULUS_LENGTH:
                        begin
                          modulus_length_we = 1'b1;
                        end

                      ADDR_EXPONENT_LENGTH:
                        begin
                          exponent_length_we = 1'b1;
                        end

                      default:
                        begin
                        end
                    endcase // case (address[7 : 0])
                  end
                else
                  begin
                    case (address[7 : 0])
                      ADDR_NAME0:
                        tmp_read_data = CORE_NAME0;

                      ADDR_NAME1:
                        tmp_read_data = CORE_NAME1;

                      ADDR_VERSION:
                        tmp_read_data = CORE_VERSION;

                      ADDR_CTRL:
                        tmp_read_data = {31'h00000000, start_reg};

                      ADDR_STATUS:
                        tmp_read_data = {31'h00000000, ready_reg};

                      ADDR_MODULUS_LENGTH:
                        tmp_read_data = {24'h000000, modulus_length_reg};

                      ADDR_EXPONENT_LENGTH:
                        tmp_read_data = {24'h000000, exponent_length_reg};

                      ADDR_LENGTH:
                        tmp_read_data = {24'h000000, length_reg};

                      default:
                        begin
                        end
                    endcase // case (address[7 : 0])
                  end
              end

            MODULUS_PREFIX:
              begin
                if (we)
                  begin
                    modulus_mem_api_we = 1'b1;
                    invalidate_residue = 1'b1;
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

            default:
              begin

              end
          endcase // case (address[11 : 8])
        end // if (cs)
    end // api


  //----------------------------------------------------------------
  // one
  //
  // generates the big integer one ( 00... 01 )
  //----------------------------------------------------------------
  always @*
    begin : one_process
      one_new = 32'h00000000;
      b_one_new = 32'h00000000;
      if (montprod_opa_addr == length_m1_reg)
        one_new = 32'h00000001;
      if (montprod_opb_addr == length_m1_reg)
        b_one_new = 32'h00000001;
    end


  //----------------------------------------------------------------
  // Read mux for modulus. Needed since it is being
  // addressed by two sources.
  //----------------------------------------------------------------
  always @*
    begin : modulus_mem_reader_process
      if (modexp_ctrl_reg == CTRL_RESIDUE)
        modulus_mem_int_rd_addr = residue_opm_addr;
      else
        modulus_mem_int_rd_addr = montprod_opm_addr;
    end


  //----------------------------------------------------------------
  // Feeds residue calculator.
  //----------------------------------------------------------------
  always @*
    begin : residue_process
      //N*2, N=length*32, *32 = shl5, *64 = shl6
      residue_nn = { 1'b0, length_reg, 6'h0 };
      residue_length = length_reg;
      residue_opm_data = modulus_mem_int_rd_data;
    end


  //----------------------------------------------------------------
  // Sets the register that decides if residue is valid or not.
  //----------------------------------------------------------------
  always @*
    begin : residue_valid_process
      if (invalidate_residue)
        residue_valid_new = 1'b0;
      else if ( residue_valid_int_validated == 1'b1)
        residue_valid_new = 1'b1;
     else
        residue_valid_new = residue_valid_reg;
    end


  //----------------------------------------------------------------
  // montprod_op_select
  //
  // Select operands used during montprod calculations depending
  // on what operation we want to do.
  //----------------------------------------------------------------
  always @*
    begin : montprod_op_select

      montprod_length          = length_reg;

      result_mem_int_rd_addr   = montprod_opa_addr;
      message_mem_int_rd_addr  = montprod_opa_addr;
      p_mem_rd0_addr           = montprod_opa_addr;

      residue_mem_montprod_read_addr = montprod_opb_addr;
      p_mem_rd1_addr                 = montprod_opb_addr;

      montprod_opm_data = modulus_mem_int_rd_data;
      case (montprod_select_reg)
        MONTPROD_SELECT_ONE_NR:
          begin
            montprod_opa_data       = one_reg;
            montprod_opb_data       = residue_mem_montprod_read_data;
          end

        MONTPROD_SELECT_X_NR:
          begin
            montprod_opa_data       = message_mem_int_rd_data;
            montprod_opb_data       = residue_mem_montprod_read_data;
          end

        MONTPROD_SELECT_Z_P:
          begin
            montprod_opa_data       = result_mem_int_rd_data;
            montprod_opb_data       = p_mem_rd1_data;
          end

        MONTPROD_SELECT_P_P:
          begin
            montprod_opa_data       = p_mem_rd0_data;
            montprod_opb_data       = p_mem_rd1_data;
          end

        MONTPROD_SELECT_Z_ONE:
          begin
            montprod_opa_data       = result_mem_int_rd_data;
            montprod_opb_data       = b_one_reg;
          end

        default:
          begin
            montprod_opa_data       = 32'h00000000;
            montprod_opb_data       = 32'h00000000;
          end
      endcase // case (montprod_selcect_reg)
    end


  //----------------------------------------------------------------
  // memory write mux
  //
  // Direct memory write signals to correct memory.
  //----------------------------------------------------------------
  always @*
    begin : memory_write_process
      result_mem_int_wr_addr = montprod_result_addr;
      result_mem_int_wr_data = montprod_result_data;
      result_mem_int_we      = 1'b0;

      p_mem_wr_addr = montprod_result_addr;
      p_mem_wr_data = montprod_result_data;
      p_mem_we      = 1'b0;

      case (montprod_dest_reg)
        MONTPROD_DEST_Z:
          result_mem_int_we = montprod_result_we;
        MONTPROD_DEST_P:
          p_mem_we = montprod_result_we;
        default:
          begin
          end
      endcase

      // inhibit Z=Z*P when ei = 0
      if (modexp_ctrl_reg == CTRL_ITERATE_Z_P)
        result_mem_int_we = result_mem_int_we & ei_reg;
    end


  //----------------------------------------------------------------
  // loop_counter
  //
  // Calculate the loop counter and related variables.
  //----------------------------------------------------------------
  always @*
    begin : loop_counters_process
      loop_counter_new = 13'b0;
      loop_counter_we  = 1'b0;

      if (loop_counter_reg == { length_m1_reg, 5'b11111 })
        last_iteration = 1'b1;
      else
        last_iteration = 1'b0;

      case (modexp_ctrl_reg)
        CTRL_CALCULATE_P0:
          begin
            loop_counter_new = 13'b0;
            loop_counter_we  = 1'b1;
          end

        CTRL_ITERATE_END:
          begin
            loop_counter_new = loop_counter_reg + 1'b1;
            loop_counter_we  = 1'b1;
          end

        default:
          begin
            loop_counter_new = loop_counter_reg;
            loop_counter_we  = 1'b0;
          end

      endcase
    end


  //----------------------------------------------------------------
  // exponent
  //
  // Reads the exponent.
  //----------------------------------------------------------------
  always @*
    begin : exponent_process
      // Accessing new instead of reg - pick up update at
      // CTRL_ITERATE_NEW to remove a pipeline stall.
      E_word_index  = length_m1_reg - loop_counter_new[ 12 : 5 ];

      E_bit_index   = loop_counter_reg[ 04 : 0 ];

      exponent_mem_int_rd_addr = E_word_index;

      ei_new = exponent_mem_int_rd_data[ E_bit_index ];

      if (modexp_ctrl_reg == CTRL_ITERATE)
        ei_we = 1'b1;
      else
        ei_we = 1'b0;
    end


  //----------------------------------------------------------------
  // modexp_ctrl
  //
  // Control FSM logic needed to perform the modexp operation.
  //----------------------------------------------------------------
  always @*
    begin
      ready_new           = 1'b0;
      ready_we            = 1'b0;
      montprod_select_new = MONTPROD_SELECT_ONE_NR;
      montprod_select_we  = 0;
      montprod_dest_new   = MONTPROD_DEST_NOWHERE;
      montprod_dest_we    = 0;
      montprod_calc       = 0;
      modexp_ctrl_new     = CTRL_IDLE;
      modexp_ctrl_we      = 1'b0;
      clear_start         = 1'b0;

      residue_calculate = 1'b0;

      residue_valid_int_validated = 1'b0;

      case (modexp_ctrl_reg)
        CTRL_IDLE:
          begin
            if (start_reg)
              begin
                ready_new       = 1'b0;
                ready_we        = 1'b1;
                modexp_ctrl_new = CTRL_DONE;
                modexp_ctrl_we  = 1'b1;

                if (residue_valid_reg)
                  begin
                    //residue has alrady been calculated, start with MONTPROD( 1, Nr, MODULUS )
                    montprod_select_new = MONTPROD_SELECT_ONE_NR;
                    montprod_select_we  = 1;
                    montprod_dest_new   = MONTPROD_DEST_Z;
                    montprod_dest_we    = 1;
                    montprod_calc       = 1;
                    modexp_ctrl_new     = CTRL_CALCULATE_Z0;
                    modexp_ctrl_we      = 1;
                  end
                else
                  begin
                    //modulus has been written and residue (Nr) must be calculated
                    modexp_ctrl_new = CTRL_RESIDUE;
                    modexp_ctrl_we  = 1;
                    residue_calculate = 1'b1;
                  end
              end
          end

        CTRL_RESIDUE:
          begin
            if (residue_ready)
              begin
                montprod_select_new = MONTPROD_SELECT_ONE_NR;
                montprod_select_we  = 1;
                montprod_dest_new   = MONTPROD_DEST_Z;
                montprod_dest_we    = 1;
                montprod_calc       = 1;
                modexp_ctrl_new     = CTRL_CALCULATE_Z0;
                modexp_ctrl_we      = 1;
                residue_valid_int_validated = 1'b1; //update registers telling residue is valid
              end
          end

        CTRL_CALCULATE_Z0:
          begin
            if (montprod_ready)
              begin
                montprod_select_new = MONTPROD_SELECT_X_NR;
                montprod_select_we  = 1;
                montprod_dest_new   = MONTPROD_DEST_P;
                montprod_dest_we    = 1;
                montprod_calc       = 1;
                modexp_ctrl_new = CTRL_CALCULATE_P0;
                modexp_ctrl_we  = 1;
              end
          end

        CTRL_CALCULATE_P0:
          begin
            if (montprod_ready == 1'b1)
              begin
                modexp_ctrl_new = CTRL_ITERATE;
                modexp_ctrl_we  = 1;
              end
          end

        CTRL_ITERATE:
          begin
            montprod_select_new = MONTPROD_SELECT_Z_P;
            montprod_select_we  = 1;
            montprod_dest_new   = MONTPROD_DEST_Z;
            montprod_dest_we    = 1;
            montprod_calc       = 1;
            modexp_ctrl_new     = CTRL_ITERATE_Z_P;
            modexp_ctrl_we      = 1;

            if (ei_new == 1'b0 && exponation_mode_reg == EXPONATION_MODE_PUBLIC_FAST)
              begin
                //Skip the fake montgomery calculation, exponation_mode_reg optimizing for speed not blinding.
                montprod_select_new = MONTPROD_SELECT_P_P;
                montprod_dest_new   = MONTPROD_DEST_P;
                modexp_ctrl_new     = CTRL_ITERATE_P_P;
              end
          end

        CTRL_ITERATE_Z_P:
            if (montprod_ready)
              begin
                montprod_select_new = MONTPROD_SELECT_P_P;
                montprod_select_we  = 1;
                montprod_dest_new   = MONTPROD_DEST_P;
                montprod_dest_we    = 1;
                montprod_calc       = 1;
                modexp_ctrl_new     = CTRL_ITERATE_P_P;
                modexp_ctrl_we      = 1;
              end

        CTRL_ITERATE_P_P:
            if (montprod_ready == 1'b1)
              begin
                modexp_ctrl_new = CTRL_ITERATE_END;
                modexp_ctrl_we  = 1;
              end

        CTRL_ITERATE_END:
          begin
            if (!last_iteration)
              begin
                modexp_ctrl_new = CTRL_ITERATE;
                modexp_ctrl_we  = 1;
              end
            else
              begin
                montprod_select_new = MONTPROD_SELECT_Z_ONE;
                montprod_select_we  = 1;
                montprod_dest_new   = MONTPROD_DEST_Z;
                montprod_dest_we    = 1;
                montprod_calc       = 1;
                modexp_ctrl_new     = CTRL_CALCULATE_ZN;
                modexp_ctrl_we      = 1;
              end
          end

        CTRL_CALCULATE_ZN:
          begin
            if (montprod_ready)
              begin
                modexp_ctrl_new = CTRL_DONE;
                modexp_ctrl_we  = 1;
              end
          end

        CTRL_DONE:
          begin
            clear_start     = 1'b1;
            ready_new       = 1'b1;
            ready_we        = 1'b1;
            modexp_ctrl_new = CTRL_IDLE;
            modexp_ctrl_we  = 1;
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

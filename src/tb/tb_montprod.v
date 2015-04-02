//======================================================================
//
// tb_montprod.v
// -------------
// Testbench for the montgomery product module.
//
//
// Author: Peter Magnusson, Joachim Strombergson
// Copyright (c) 2014, Assured AB
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

//------------------------------------------------------------------
// Simulator directives.
//------------------------------------------------------------------
`timescale 1ns/100ps

//------------------------------------------------------------------
// Test module.
//------------------------------------------------------------------

module tb_montprod();

//----------------------------------------------------------------
// Internal constant and parameter definitions.
//----------------------------------------------------------------
  parameter SHOW_INIT = 0;

  parameter DUMP_MEM = 0;
  parameter DEBUG = 0;
  parameter CLK_HALF_PERIOD = 2;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;


//----------------------------------------------------------------
// Register and Wire declarations.
//----------------------------------------------------------------

reg           tb_clk;
reg           tb_reset_n;
reg           tb_calculate;
wire          tb_ready;
reg  [ 7 : 0] tb_length;
wire [ 7 : 0] tb_opa_addr;
reg  [31 : 0] tb_opa_data;
wire [ 7 : 0] tb_opb_addr;
reg  [31 : 0] tb_opb_data;
wire [ 7 : 0] tb_opm_addr;
reg  [31 : 0] tb_opm_data;
wire [ 7 : 0] tb_result_addr;
wire [31 : 0] tb_result_data;
wire          tb_result_we;

reg [31 : 0] tb_a [0 : 255]; //tb_opa_data
reg [31 : 0] tb_b [0 : 255]; //tb_opb_data reads here
reg [31 : 0] tb_m [0 : 255]; //tb_opm_data reads here
reg [31 : 0] tb_r [0 : 255]; //tb_result_data writes here

  reg monitor_s;

integer test_mont_prod_success;
integer test_mont_prod_fail;

//----------------------------------------------------------------
// Device Under Test.
//----------------------------------------------------------------

montprod dut(
 .clk(tb_clk),
 .reset_n(tb_reset_n),
 .length(tb_length),
 .calculate(tb_calculate),
 .ready(tb_ready),
 .opa_addr(tb_opa_addr),
 .opa_data(tb_opa_data),
 .opb_addr(tb_opb_addr),
 .opb_data(tb_opb_data),
 .opm_addr(tb_opm_addr),
 .opm_data(tb_opm_data),
 .result_addr(tb_result_addr),
 .result_data(tb_result_data),
 .result_we(tb_result_we)
);

always @(posedge tb_clk)
  begin : read_test_memory
    tb_opa_data <= tb_a[tb_opa_addr];
    tb_opb_data <= tb_b[tb_opb_addr];
    tb_opm_data <= tb_m[tb_opm_addr];

    if (DUMP_MEM)
      $display("a %x %x b %x %x m %x %x", tb_opa_addr, tb_a[tb_opa_addr], tb_opb_addr, tb_b[tb_opb_addr], tb_opm_addr, tb_m[tb_opm_addr]);
  end

always @*
  begin : write_test_memory
    if (tb_result_we == 1'b1)
      begin
        $display("write %d: %x", tb_result_addr, tb_result_data);
        tb_r[tb_result_addr] = tb_result_data;
      end
  end


//----------------------------------------------------------------
// clk_gen
//
// Clock generator process.
//----------------------------------------------------------------
always
  begin : clk_gen
    #CLK_HALF_PERIOD tb_clk = !tb_clk;
  end // clk_gen


//----------------------------------------------------------------
// S monitor
//----------------------------------------------------------------
  always @ (posedge tb_clk)
    begin : s_monitor
      if (monitor_s)
        $display("S[ 0 ]: %x", dut.s_mem.mem[0] );
    end



//----------------------------------------------------------------
// S monitor
//----------------------------------------------------------------
  always @ (posedge tb_clk)
    begin : s_write_minitor
      if (monitor_s)
        if (dut.s_mem_we)
          $display("Write to S[0x%02x]: 0x%08x", dut.s_mem_wr_addr, dut.s_mem_new);
    end



//----------------------------------------------------------------
//----------------------------------------------------------------
  always @ (posedge tb_clk)
    begin : bq_debug
      if (dut.montprod_ctrl_reg == dut.CTRL_L_CALC_SM)
        $display("====================> B: %x Q: %x B_bit_index_reg: %x <=====================", dut.b_reg, dut.q_reg, dut.B_bit_index_reg);
    end

      //case (montprod_ctrl_reg)
      //  CTRL_LOOP_BQ:
      //     $display("DEBUG: b: %d q: %d opa_data %x opb_data %x s_mem_read_data %x", b, q, opa_addr_reg, opa_data, opb_data, s_mem_read_data);
      //  default:
      //    begin end
      //endcase

//----------------------------------------------------------------
//----------------------------------------------------------------
  always @ (posedge tb_clk)
    begin : fsm_debug
      if (dut.montprod_ctrl_we)
        case (dut.montprod_ctrl_new)
          dut.CTRL_IDLE:
            $display("FSM: IDLE");
          dut.CTRL_INIT_S:
            $display("FSM: INIT_S");
          dut.CTRL_LOOP_INIT:
            $display("FSM: LOOP_INIT");
          dut.CTRL_LOOP_ITER:
            $display("FSM: LOOP_ITER");
          dut.CTRL_LOOP_BQ:
            $display("FSM: LOOP_BQ");
          dut.CTRL_L_CALC_SM:
            $display("FSM: LOOP_CALC_SM");
          dut.CTRL_L_CALC_SA:
            $display("FSM: LOOP_CALC_SA");
          dut.CTRL_L_STALLPIPE_SA:
            $display("FSM: STALL_PIPE");
          dut.CTRL_L_CALC_SDIV2:
            $display("FSM: LOOP_CALC_SDIV2");
          dut.CTRL_EMIT_S:
            $display("FSM: LOOP_EMIT_S");
          dut.CTRL_DONE:
            $display("FSM: DONE");
          default:
            $display("FSM: %x", dut.montprod_ctrl_new);
        endcase
    end


//----------------------------------------------------------------
// reset_dut()
//
// Toggles reset to force the DUT into a well defined state.
//----------------------------------------------------------------
task reset_dut();
  begin
    $display("*** Toggle reset.");
    tb_reset_n = 0;
    #(4 * CLK_HALF_PERIOD);
    tb_reset_n = 1;
  end
endtask // reset_dut

//----------------------------------------------------------------
// init_sim()
//
// Initialize all counters and testbed functionality as well
// as setting the DUT inputs to defined values.
//----------------------------------------------------------------
task init_sim();
  begin
    $display("*** init_sim");
    tb_clk        = 0;
    tb_reset_n    = 0;
    tb_length     = 0;
    tb_calculate  = 0;
    monitor_s = 1;
    test_mont_prod_success = 0;
    test_mont_prod_fail    = 0;
  end
endtask // init_dut

//----------------------------------------------------------------
// wait_ready()
//
// Wait for the ready flag in the dut to be set.
//
// Note: It is the callers responsibility to call the function
// when the dut is actively processing and will in fact at some
// point set the flag.
//----------------------------------------------------------------
task wait_ready();
  begin
    $display("*** wait_ready");
    begin: wait_loop
      integer i;
      for (i=0; i<1000000; i=i+1)
        if (tb_ready == 0)
          #(2 * CLK_HALF_PERIOD);
    end
    if (tb_ready == 0)
       begin
         $display("*** wait_ready failed, never became ready!");
         $finish;
       end
  end
endtask // wait_ready

//----------------------------------------------------------------
//----------------------------------------------------------------
task signal_calculate();
  begin
    $display("*** signal_calculate");
    tb_calculate = 1;
    #(2 * CLK_HALF_PERIOD);
    tb_calculate = 0;
  end
endtask // signal_calculate


//----------------------------------------------------------------
// Tests the montgomery multiplications
//----------------------------------------------------------------
task test_mont_prod(
    input [7 : 0]      length,
    input [0 : 8192-1] a,
    input [0 : 8192-1] b,
    input [0 : 8192-1] m,
    input [0 : 8192-1] expected
  );
  begin
    $display("*** test started");
    begin: copy_test_vectors
      integer i;
      integer j;

      $display("*** Initializing...");
      for (i=32'h0; i<256; i=i+1)
        begin
          j = {i, 5'h0};
          tb_a[i] = a[j +: 32];
          tb_b[i] = b[j +: 32];
          tb_m[i] = m[j +: 32];
          tb_r[i] = 32'h0;
          if (SHOW_INIT)
            $display("*** init %0x: a: %x b: %x m: %x r: %x", i, tb_a[i], tb_b[i], tb_m[i], tb_r[i]);
        end
    end

    $display("*** Test vector copied");
    wait_ready();
    tb_length = length;
    signal_calculate();
    wait_ready();
    begin: verify_test_vectors
      integer i;
      integer j;
      integer success;
      integer fail;
      success = 1;
      fail = 0;
      for (i=0; i<length; i=i+1)
        begin
          j = i * 32;
          $display("offset: %02d expected 0x%08x actual 0x%08x", i, expected[j +: 32], tb_r[i]);
          if (expected[j +: 32] != tb_r[i])
            begin
              success = 0;
              fail = 1;
            end
        end
      test_mont_prod_success = test_mont_prod_success + success;
      test_mont_prod_fail    = test_mont_prod_fail + fail;
    end

    $display("*** test stopped");
  end
endtask

//----------------------------------------------------------------
// The main test functionality.
//----------------------------------------------------------------
initial
  begin : montgomery_product_tests
    $display("   -- Testbench for montprod started --");
    init_sim();
    reset_dut();

//* A=  b B= 11 M= 13 A*B= 10 Ar=  9 Br=  7 Ar*Br=  1 A*B= 10

    test_mont_prod( 1, {32'h9, 8160'h0}, {32'h7, 8160'h0}, {32'h13,8160'h0}, {32'h1,8160'h0} );

//* A=  b B= 13 M= 11 A*B=  5 Ar=  b Br=  2 Ar*Br=  5 A*B=  5

    test_mont_prod( 1, {32'hb, 8160'h0}, {32'h2, 8160'h0}, {32'h11,8160'h0}, {32'h5,8160'h0} );

//* A= 11 B=  b M= 13 A*B= 10 Ar=  7 Br=  9 Ar*Br=  1 A*B= 10

    test_mont_prod( 1, {32'h7, 8160'h0}, {32'h9, 8160'h0}, {32'h13,8160'h0}, {32'h1,8160'h0} );

//* A= 11 B= 13 M=  b A*B=  4 Ar=  2 Br=  a Ar*Br=  5 A*B=  4

    test_mont_prod( 1, {32'h2, 8160'h0}, {32'ha, 8160'h0}, {32'h0b,8160'h0}, {32'h5,8160'h0} );

//* A= 13 B=  b M= 11 A*B=  5 Ar=  2 Br=  b Ar*Br=  5 A*B=  5
//* A= 13 B= 11 M=  b A*B=  4 Ar=  a Br=  2 Ar*Br=  5 A*B=  4
//* A=10001 B= 11 M= 13 A*B=  7 Ar= 11 Br=  7 Ar*Br=  4 A*B=  7
//* A=10001 B= 13 M= 11 A*B=  4 Ar=  2 Br=  2 Ar*Br=  4 A*B=  4
//* A= 11 B=10001 M= 13 A*B=  7 Ar=  7 Br= 11 Ar*Br=  4 A*B=  7
//* A= 11 B= 13 M=10001 A*B=143 Ar= 11 Br= 13 Ar*Br=143 A*B=143
//* A= 13 B=10001 M= 11 A*B=  4 Ar=  2 Br=  2 Ar*Br=  4 A*B=  4
//* A= 13 B= 11 M=10001 A*B=143 Ar= 13 Br= 11 Ar*Br=143 A*B=143
//* A=10001 B= 11 M=7fffffff A*B=110011 Ar=20002 Br= 22 Ar*Br=220022 A*B=110011
//* A=10001 B=7fffffff M= 11 A*B= 10 Ar=  2 Br=  8 Ar*Br= 10 A*B= 10
//* A= 11 B=10001 M=7fffffff A*B=110011 Ar= 22 Br=20002 Ar*Br=220022 A*B=110011
//* A= 11 B=7fffffff M=10001 A*B=7ff8 Ar= 11 Br=8000 Ar*Br=7ff8 A*B=7ff8
//* A=7fffffff B=10001 M= 11 A*B= 10 Ar=  8 Br=  2 Ar*Br= 10 A*B= 10
//* A=7fffffff B= 11 M=10001 A*B=7ff8 Ar=8000 Br= 11 Ar*Br=7ff8 A*B=7ff8

    //debug A =>        0        0        1 
    //debug B =>        0        0     4000 
    //debug M =>  1ffffff ffffffff ffffffff 
    //debug s =>        0        0       80 
    test_mont_prod( 3, {96'h1, 8096'h0}, {96'h4000, 8096'h0}, {96'h1ffffffffffffffffffffff,8096'h0}, {96'h80,8096'h0} );

 //debug A => 00000000 098b0437 ae647838 09d930b9 a1d269d5 03579a63 9c4e3ac5 fd070836 413389c2 321cfe8b a6a5732e bc7cbcf8 a2f1df87 19f7a767 43ef9b5d 6bd33597 23bfc574 8ec046da 5419d7ff 31811123 740b227b 709f3ace e53ba5cc 38cbc161 a0c15c88 64f26a18 423692ef a5e52a20 80d9f244 717aa2d5 e1a6680a b29eed64 57c6b005 
 //debug B => 00000000 098b0437 ae647838 09d930b9 a1d269d5 03579a63 9c4e3ac5 fd070836 413389c2 321cfe8b a6a5732e bc7cbcf8 a2f1df87 19f7a767 43ef9b5d 6bd33597 23bfc574 8ec046da 5419d7ff 31811123 740b227b 709f3ace e53ba5cc 38cbc161 a0c15c88 64f26a18 423692ef a5e52a20 80d9f244 717aa2d5 e1a6680a b29eed64 57c6b005 
 //debug M => 00000000 f14b5a0a 122ff247 85813db2 02c0d3af bd0a4615 2889ff7d 8f655e9e c866e586 f21003a0 e969769b 127ec8a5 67f07708 217775f7 7654cabc 3a624f9b 4074bdf1 55fa84c0 0354fe59 0ad04cfd 14e666c0 ce6cea72 788c31f4 edcf3dd7 3a5a59c1 b9b3ef41 565df033 69a82de8 f18c2793 0abd5502 f3730ec0 d1943dc4 a660a267 
 //debug s => 00000000 0a8a4a44 40e5c3b0 a05383c2 4ad92fc9 0af7b72e d22fa180 f3a99e64 38ffbe72 3854bc5e 93fffa55 ce49b2cf f809c9eb 81176d8b 4f8b942c 3de18f9c 6393a70a 89924a58 5684cb90 acfd1bde b408b2c0 a8d862c1 74b5a10d 90532d4e 79fe2f50 430decda 0ed75e0a ac354c46 69ce0bd8 eb36e857 b55623d1 527b9711 86cd4d75 

    test_mont_prod(
       33,
{ 1056'h098b0437ae64783809d930b9a1d269d503579a639c4e3ac5fd070836413389c2321cfe8ba6a5732ebc7cbcf8a2f1df8719f7a76743ef9b5d6bd3359723bfc5748ec046da5419d7ff31811123740b227b709f3acee53ba5cc38cbc161a0c15c8864f26a18423692efa5e52a2080d9f244717aa2d5e1a6680ab29eed6457c6b005
, 7136'h0 },
{ 1056'h098b0437ae64783809d930b9a1d269d503579a639c4e3ac5fd070836413389c2321cfe8ba6a5732ebc7cbcf8a2f1df8719f7a76743ef9b5d6bd3359723bfc5748ec046da5419d7ff31811123740b227b709f3acee53ba5cc38cbc161a0c15c8864f26a18423692efa5e52a2080d9f244717aa2d5e1a6680ab29eed6457c6b005
, 7136'h0 },
{1056'hf14b5a0a122ff24785813db202c0d3afbd0a46152889ff7d8f655e9ec866e586f21003a0e969769b127ec8a567f07708217775f77654cabc3a624f9b4074bdf155fa84c00354fe590ad04cfd14e666c0ce6cea72788c31f4edcf3dd73a5a59c1b9b3ef41565df03369a82de8f18c27930abd5502f3730ec0d1943dc4a660a267
, 7136'h0 },
{1056'h0a8a4a4440e5c3b0a05383c24ad92fc90af7b72ed22fa180f3a99e6438ffbe723854bc5e93fffa55ce49b2cff809c9eb81176d8b4f8b942c3de18f9c6393a70a89924a585684cb90acfd1bdeb408b2c0a8d862c174b5a10d90532d4e79fe2f50430decda0ed75e0aac354c4669ce0bd8eb36e857b55623d1527b971186cd4d75
, 7136'h0 });

    $display("   -- Testbench for montprod done. --");
    $display(" tests success: %d", test_mont_prod_success);
    $display(" tests failed:  %d", test_mont_prod_fail);
    $finish;
  end // montprod
endmodule // tb_montprod

//======================================================================
// EOF tb_montprod.v
//======================================================================

//======================================================================
//
// tb_residue.v
// ------------
// Testbench: Modulus 2**2N residue calculator for montgomery calculations.
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

//------------------------------------------------------------------
// Simulator directives.
//------------------------------------------------------------------
`timescale 1ns/100ps

//------------------------------------------------------------------
// Test module.
//------------------------------------------------------------------

module tb_residue();


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
reg  [14 : 0] tb_nn;
reg  [ 7 : 0] tb_length;
wire [ 7 : 0] tb_opa_rd_addr;
wire [31 : 0] tb_opa_rd_data;
wire [ 7 : 0] tb_opa_wr_addr;
wire [31 : 0] tb_opa_wr_data;
wire          tb_opa_wr_we;
wire [ 7 : 0] tb_opm_addr;
wire [31 : 0] tb_opm_data;
wire [ 7 : 0] tb_result_addr;
wire [31 : 0] tb_result_data;
wire          tb_result_we;

integer test_residue_success;
integer test_residue_fail;

//----------------------------------------------------------------
// Device Under Test
//----------------------------------------------------------------

residue dut(
  .clk(tb_clk),
  .reset_n(tb_reset_n),
  .calculate(tb_calculate),
  .ready(tb_ready),

  .nn(tb_nn), //MAX(2*N)=8192*2 (14 bit) 
  .length(tb_length),

  .opa_rd_addr(tb_opa_rd_addr),
  .opa_rd_data(tb_opa_rd_data),
  .opa_wr_addr(tb_opa_wr_addr),
  .opa_wr_data(tb_opa_wr_data),
  .opa_wr_we(tb_opa_wr_we),

  .opm_addr(tb_opm_addr),
  .opm_data(tb_opm_data)
);

//----------------------------------------------------------------
// Memory
//----------------------------------------------------------------

blockmem1r1w mem_a( //Memory to be loaded with 2**N modulus N
  .clk(tb_clk),
  .read_addr(tb_opa_rd_addr),
  .read_data(tb_opa_rd_data),
  .wr(tb_opa_wr_we),
  .write_addr(tb_opa_wr_addr),
  .write_data(tb_opa_wr_data)
); 

blockmem1r1w mem_m( // Modulus M memory
  .clk(tb_clk),
  .read_addr(tb_opm_addr),
  .read_data(tb_opm_data),
  .wr(1'b0),
  .write_addr(8'h0),
  .write_data(32'h0)
);

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
// Debug monitor the FSM
//----------------------------------------------------------------
//always @ (posedge tb_clk)
//  begin : fsm_debug
//    if (dut.residue_ctrl_we)
//      case (dut.residue_ctrl_new)
//        dut.CTRL_IDLE:
//          $display("FSM: IDLE");
//        default:
//          $display("FSM: %x", dut.residue_ctrl_new);
//      endcase
//  end

//----------------------------------------------------------------
// Debug monitor the loop counter
//----------------------------------------------------------------
//always @*
//  $display("*** loop counter: %x, nn: %x ", dut.loop_counter_1_to_nn_reg, dut.nn_reg);

//----------------------------------------------------------------
// Debug monitor writes
//----------------------------------------------------------------
//always @*
//  if (tb_opa_wr_we === 1'b1)
//    $display("*** write mem[%x] = [%x] ", tb_opa_wr_addr, tb_opa_wr_data);

//----------------------------------------------------------------
// Debug monitor one
//----------------------------------------------------------------
always @*
  $display("*** one = [%x] ", dut.one_data);

//----------------------------------------------------------------
// Debug monitor comparision
//----------------------------------------------------------------
//always @*
//  if (dut.residue_ctrl_reg == dut.CTRL_COMPARE_STALL)
//    $display("*** CF = [%x] ", dut.sub_carry_in_reg);
//always @*
//  $display("*** CFnew = [%x] ", dut.sub_carry_in_new);
//always @*
//  $display("*** CFreg = [%x] ", dut.sub_carry_in_reg);
//always @*
//  if (dut.residue_ctrl_reg == dut.CTRL_COMPARE)
//    $display("*** COMPARE (CFin=%x) A-M: %x - %x = %x (CFout=%x) addr: %x %x", dut.sub_carry_in_reg, dut.opa_rd_data, dut.opm_data, dut.sub_data, dut.sub_carry_out, dut.opa_rd_addr, dut.opm_addr);
    

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
    test_residue_success = 0;
    test_residue_fail    = 0;
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
      for (i=0; i<100000000; i=i+1)
        if (tb_ready == 0)
          #(2 * CLK_HALF_PERIOD);
        else if (tb_ready === 1)
          i = 100000000000000000000;
    end
    if (tb_ready == 0)
       begin
         $display("*** wait_ready failed, never became ready!");
         $finish;
       end
    else
    $display("*** wait_ready: done");
  end
endtask // wait_ready

//----------------------------------------------------------------
// Tells the DUT to start doing its magic!
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
// Tests the residue calculator
//----------------------------------------------------------------
task test_residue(
    input [7 : 0]      length,
    input [14 : 0]     nn,
    input [0 : 8192-1] m,
    input [0 : 8192-1] expected
  );
  begin
    $display("*** test started");
    begin: copy_test_vectors
      integer i;
      integer j;
      reg [31 : 0] aa;
      reg [31 : 0] mm;

      $display("*** Initializing...");
      for (i=32'h0; i<256; i=i+1)
        begin
          j = {i, 5'h0};
          mm = m[j +: 32];
          mem_m.mem[i] = mm;
          if (SHOW_INIT)
            $display("*** init %0x: m: %x", i, mm);
        end
    end

    $display("*** Test vector copied");
    wait_ready();
    tb_length = length;
    tb_nn = nn;
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
          $display("offset: %02d expected 0x%08x actual 0x%08x", i, expected[j +: 32], mem_a.mem[i]);
          if (expected[j +: 32] !== mem_a.mem[i])
            begin
              success = 0;
              fail = 1;
            end
        end
      test_residue_success = test_residue_success + success;
      test_residue_fail    = test_residue_fail + fail;
    end

    $display("*** test stopped");
  end
endtask

//----------------------------------------------------------------
// The main test functionality.
//----------------------------------------------------------------
initial
  begin : modulus_residue_tests
    $display("   -- Testbench for residue started --");
    init_sim();
    reset_dut();


    //Verify that 1**(2*32) mod 8 == 0; i.e. does the compare pick up 8==8 => SUB work? 
    test_residue( 1, 32, { 32'h08, 8160'h0 }, { 32'h0, 8160'h0 } );

//m_residue_2_2N_array N:  96
//m_residue_2_2N_array M:    1ffffff ffffffff ffffffff 
//m_residue_2_2N_array Nr:         0        0     4000 

    test_residue( 3, 96+96, { 96'h1ffffffffffffffffffffff, 8096'h0 }, { 96'h4000, 8096'h0 } );


//test_modExp_4096bit_e65537
//m_residue_2_2N_array N:  4128
//m_residue_2_2N_array M:   00000000 ecc9307c 57a39970 7e9e2569 872cd790 0d4dddcc 704fd131 9395388d 07e63a16 37ea6fae 3873a01e 0df4a57b b90bc708 a05ade61 91ef3868 58db06db 893e2d41 c75bb93d 0c7f3be8 8f57c9f9 477efa62 f509e077 568d59aa 28552ee8 a042f88d f776a12d 19f3685b 1205c3f7 fb7db6c5 354908b1 099640c0 709ab3e8 e76149de 6bc111d2 95210730 bab8e493 95168d09 5242aba5 4b98da8a b755eb64 246c6732 c8fd54f4 f6ed5686 6ca61ceb 239f1133 1abdc477 24a35c02 baef93b4 6b856235 b34318c6 420da1a7 a94a7298 53141662 0bfb5c3d 183fa12c 5c4b3e4a 6cd2f7cd c5446327 6e90cf3e 07fe2e20 78fe3b26 73419d8f e5c5666d ce01b1c7 c45ce6da 9ca6e8ed 42ec9161 5ec6d3ec 72921ad2 8f4a9496 b146e974 c9ca5c00 fdea07f5 d8a27ee8 42507619 6ee518c8 4a626aaf e099db09 b2d44800 44ca5299 74b3edd3 bafd6615 042e345d a39c8000 bc42f7b0 1d8fc65b 02a73859 f1bf3dac 33473f8a ccd0d5c8 4e355e77 008b1ae1 77c43bde f2fa7e9a 1828147e 2dca431f 612fc4c0 2c652d44 55996f19 b367f72e 9958b270 a96f7b1f fbb230e3 e70791fd 6e9d6402 98dbd1dd ea7f1494 65a4602d 93726a54 53876bb3 57c6041b 7a83ee09 244588ce d4cf9317 d77add56 c7e63f59 c2b65e19 b3982427 cfc4c9a1 8bef7de2 addc6cad b4bee49f 46edae94 f3dba909 c74d8a1c bd470d28 7f0dc6b1 a5cc5313 d47ef6b3 
//m_residue_2_2N_array Nr:  00000000 d41b628b a651c4d2 f697e11a 71d9b46b eb909ee1 ba9f2866 247ec50c 5a0eefbf 370da146 50adff1b b1b2c306 9f099d33 bc5caced 6825cee8 c69854a9 3448e0ea e5309441 d1ff98fa a71e5f87 8bc1b1f0 db05a40d 11985c39 0be193ef 0ccdc291 114ea54c 876ca7ef 0594a93b c424f13a d76a0868 cae2f8fd c1b44a38 5c612274 cd29a45f 4f182e90 eb43bcba 9a000a0c deb6d313 52ce2c6e f12ee479 299ce548 34ff35a5 2b4ab09c 3bfa7f84 0d616f5b 5457cb5b 15aaab76 fb904268 5088c2a6 bcbe1468 38f7dc3d 701330df c4f40fcd 0638af14 8692e4b7 767954fd a6893478 5a91b140 1b1e485a 8adc96a2 07e759e9 848423f2 62d6a289 ad9285bc 1e3d7a5a fb9c5180 e03f81ad 368cc5d2 959f8eaa 35e838a7 abc569ac 8dda502f c223e06e ea080538 0a6cc7e3 1ea9e372 46507f0b 8ad3ea99 d1a1c7a3 7c4f2a85 9eaaa209 f657a18b 176cc2c9 1037574b 8dc3fe47 9022a011 d18d44bf 1f404e19 cc4f5ba9 5b485a04 0aae86f8 45d81818 5424ea78 e04be04a 06933389 da3814d4 a9262a03 ade10611 96a30c14 ab125031 d376fe2b 65ec657b 95276df4 081d41c7 1eea6002 f045ac1d 62ad9a84 c51553b4 5c5e096e fa3b0fc1 c5be625c 8aecf00c 65e89e46 6bc875f0 badc249c 6e2502cf 10896316 b8c8706e 9838a060 247f2f09 c88f1fe6 798e32b3 be1df9e4 d69f2e85 f0021691 8f737ba0 66e60f6f 502c7476 f78bcafd 


test_residue(129,4128+4128,{4128'h00000000ecc9307c57a399707e9e2569872cd7900d4dddcc704fd1319395388d07e63a1637ea6fae3873a01e0df4a57bb90bc708a05ade6191ef386858db06db893e2d41c75bb93d0c7f3be88f57c9f9477efa62f509e077568d59aa28552ee8a042f88df776a12d19f3685b1205c3f7fb7db6c5354908b1099640c0709ab3e8e76149de6bc111d295210730bab8e49395168d095242aba54b98da8ab755eb64246c6732c8fd54f4f6ed56866ca61ceb239f11331abdc47724a35c02baef93b46b856235b34318c6420da1a7a94a7298531416620bfb5c3d183fa12c5c4b3e4a6cd2f7cdc54463276e90cf3e07fe2e2078fe3b2673419d8fe5c5666dce01b1c7c45ce6da9ca6e8ed42ec91615ec6d3ec72921ad28f4a9496b146e974c9ca5c00fdea07f5d8a27ee8425076196ee518c84a626aafe099db09b2d4480044ca529974b3edd3bafd6615042e345da39c8000bc42f7b01d8fc65b02a73859f1bf3dac33473f8accd0d5c84e355e77008b1ae177c43bdef2fa7e9a1828147e2dca431f612fc4c02c652d4455996f19b367f72e9958b270a96f7b1ffbb230e3e70791fd6e9d640298dbd1ddea7f149465a4602d93726a5453876bb357c6041b7a83ee09244588ced4cf9317d77add56c7e63f59c2b65e19b3982427cfc4c9a18bef7de2addc6cadb4bee49f46edae94f3dba909c74d8a1cbd470d287f0dc6b1a5cc5313d47ef6b3 , 4064'h0 },
{4128'h00000000d41b628ba651c4d2f697e11a71d9b46beb909ee1ba9f2866247ec50c5a0eefbf370da14650adff1bb1b2c3069f099d33bc5caced6825cee8c69854a93448e0eae5309441d1ff98faa71e5f878bc1b1f0db05a40d11985c390be193ef0ccdc291114ea54c876ca7ef0594a93bc424f13ad76a0868cae2f8fdc1b44a385c612274cd29a45f4f182e90eb43bcba9a000a0cdeb6d31352ce2c6ef12ee479299ce54834ff35a52b4ab09c3bfa7f840d616f5b5457cb5b15aaab76fb9042685088c2a6bcbe146838f7dc3d701330dfc4f40fcd0638af148692e4b7767954fda68934785a91b1401b1e485a8adc96a207e759e9848423f262d6a289ad9285bc1e3d7a5afb9c5180e03f81ad368cc5d2959f8eaa35e838a7abc569ac8dda502fc223e06eea0805380a6cc7e31ea9e37246507f0b8ad3ea99d1a1c7a37c4f2a859eaaa209f657a18b176cc2c91037574b8dc3fe479022a011d18d44bf1f404e19cc4f5ba95b485a040aae86f845d818185424ea78e04be04a06933389da3814d4a9262a03ade1061196a30c14ab125031d376fe2b65ec657b95276df4081d41c71eea6002f045ac1d62ad9a84c51553b45c5e096efa3b0fc1c5be625c8aecf00c65e89e466bc875f0badc249c6e2502cf10896316b8c8706e9838a060247f2f09c88f1fe6798e32b3be1df9e4d69f2e85f00216918f737ba066e60f6f502c7476f78bcafd , 4064'h0 });

// ----- test_modExp_8192_e65537 -----
//m_residue_2_2N_array N:  8224
//m_residue_2_2N_array M:          0 9985a7f5 b471b248 d13838a3 75e22fc7  e0d72b0 6ea72eb3 958b1b8e 431cb10d 72421e7e b0e33fa3 c5b6d437 b7c1ce28 e4960b94 7c36159e c98580a1 2c98a45e 8c0a5d37 65bdbb62 707d3cec  3d2d25e d8e420e8 ec24c78b ec2f2dbe 97572117 5933fa87  1440858 cf4e5a64 e6a0f624 59c0e042 83d52d2c 6c4144c0 112769f5 86b85e44 434015d2 b4473787 1f33a844  c717bf3 ea8228f0 7b46cbc4 28c15ea0 a4bdda03 27314b2f 6ea6856e ec9cbd40 40cfea29 f5fab20a 3726bdc0 74eb6930 52cf502a f77f8d47 f27acfeb 901c570d da0c86f6 96bd21c3 e0c42ff8 3244ae66 490c9e5e 32abf7ad 9f467988 a2bd97e5 7b053c1c 9dfd9bf0 836a6d08 7f7f12e8 13ac2747 79fc03b1 f452cd02 78662a82 f67bab98 a4a6bf69 ba098c38 6f3b14b0 92dc6f3e 4a71c587 8e901015 cfa583b6 f8af38f2 3ac2f6ed d433f6c4 214cb499  e2bb7b1 ff121c3d 70c8567e 5ee2a3b0 926fc6d1 2ed64fed b34139d8  1357ef6  11edb10  8253a72  9549e5f 6f2efebd 7f0c8957 92579f0c  b7af9de a74e4d78 6623c204  1df02fb 3f5b2a7a c32accc1 e4ee37d3 6a31107c a6b0cc97 38378a05 d20b36a5 64a71a1a 371e20d6 5802ab92 aff5961b dcdac5d3 7ae73afc 66d7a7a0 eca201a5 8f1bd259 d1210db9 2a9e3e13 ff238682 a5951228 c54e9667 85db95b2 34a56c30 3535ebce dbc90290 4a29445b 92c0d1a4 1575edf7 d9fa0ff9 f56b1e63 c4a193ac f5184572 b6496b0c 6f91242f 46026714 adb65332 3514bbea 9e41a9d7 4f6b34ef aa807f4e 4a0aed66 456c5a4f 21b6283c 704b7670 f3d1bbb1 e3f7c1ab c52b5fe0 7ab11f42 c6dcc8b2 5547689d 4c4808f0 353d809f 4c670bc0 bc3d6825 3262efce f692ffe6 216f842a a0a75fc7 3ff0874b 6e8b2052 3aff2ef1 e095eca1 23cbceeb a0303b50 5cf66579 5d359223 86cc19c0 59b365fa d8246c23 a615adb6 e5d7eee5 c9749976 9e7ea208 acfcb6cf 23803b8c 65eeb750 bcb3c4a0 f99a6721 bcb8d46f e0a4c149 18e18f68 4916c065 5c492551 3ecb0227 48714459 55b47877 b6e40f75 64bb763c 82be2c06 2023ba3f 9f1b2958 163af75a f0f63eba e8c7ad30 91437810 bc78b73f d0ef4e44 211b41e1 656707b4 6f4c916d 10aa0301 258ac87e cc39eefe 5f332447 d645e269 cb2d162a 9a587c06 7852e9f0 c5d24de9 8dc5227d 13605de1 63444a09 87bd3b72 e1873b32 b9d62892 4d76782f 5310b181 60336fc9 7cc2fe76 a51c80f0  bc4fb31 ee659283 ef3c1b61 a1861d2a 82c69517 2283a0e2  48cb25e 5ae032a5 ab454efa 21c999ea 7e711d04 87637f43 ee2ad2d6 7b681e4d f5a45708 207c634b d997f0fb a59fcf3f bb096b59 57f96720 fe0108cb f2ae1bc7 f460f10b 9767fe9c d2e48ba7 6c23f61a  d82f70f da11f4b3 c506afb4 b42316fb  188f9c8 cea8efbc b0ec2877 5201df13 93c7f871 1400e066 dbe6df0f d212da97 
//m_residue_2_2N_array Nr:         0 72f3903e 3f18548d e26585c2 af1e07a7 702224df  dff934d eb67d0b4 6a045abf e862d07d 91fed83c d48a17a4 31e44448 fad86891 dd6a0ab6 1abd8580 738a05d4 60dc5bad f114312c c41a1222 2ef5a5fa be62f6fd 57a3b9bf e10a1884 eeef8d4e 4f98d513 fbea6fb7 23ff8744 531b8f85 779afc60 966d8b3e 9e276968 5ccd04dd 24b0f4b0 2199d76d 59ec5b9f 3d9d1456  dc07107 a56596ee 3afe5ae5 59261595 e8c132bb 8c94c31f 201b4b66 4bb2be56 f66b7146 19e51695  eac7b76 68e7c8b0 10649618 24dea4b2 8e12cf77 d7bbe149 f7f8e1cd ab453da4 adff6562 11f48c88 8c92a63c 938570a2 a12e83ca   331ff0 cceeb3e2 bc7aae23 e83e406c f2aa64bf 3329b8df 9d63129c 63da0058 c619f75f 20870d2a dce8776a 4745ad09 d4f1629b 8c217213 40e4bdad 39fcd8d5 5eac498e 15f7cb59 eda51b97 37fe8a0a d0845e7d 8e1ea7ae 34aa5242 86e75a46 e5a4d972 4808f345 e6173d49 633e1502 631cfd0b 3816fb56 83b4c9e5 ac1c9a93 4f9cbfab a6c2d865 758454d1 63648d26 bcceda3d c19e504c ab610eaf 51de9032 4a05c93b  b799495 a57a7583 97bd6c2b 92928d18 a571e3e2 534d3ab2 1f4d6cef bde6d238 dd63d8dc e2aa4e87 912d3790 6697d0fd dabfb4a0 d6e5ef53 439f16bc 2a8bdc91 4a88e2ea bc7c6e04 f089b1ea ea048065 69a9f8cc 88e56c70 c335bc4e  df83d43 613cfa32 95125b16 aa935841 ff4f8505 1d71b934  ec5b936 4f140307 57caecf5 6495fbf1 666cbdf9  80dc919 7d3e83ae 81971757 1739be85 d69f1715 1152bd6e 66175aff  354f7b8 85c88178 607f2a34 9d916029 a66a6d54 2e0ca013 def11bb1 162bcf54 d7414eb6 15bc4416 6b50439a c7a43ab3 2f8aedf9 c4f07c06 9c2089c3 708921e4 ad31458a 9be68d18 2fede701 858d3223 bbcfa753  39a7a4f b73c4486 4f6dd940 65f20d55 1f107ef9 ab6a34e7 ce3f13d4  3de1075 70aab66b a0c28302 8e094205 d6b7a9ef 1dbd9e7f e83b8fcf a18becd2 119bc734  f533946 7f00d46f 92fff102 a636bebf 434b69af 63d8c1b7 67a5935d 969121f4 80f52405 3e6523dc fd10ebc1 e9d62016 c3d6faf3 d86912d0 f544eb90 e42e68b5 4f9b3097 7e745994 376b2824 2ab61734 44285064 e6348a45 eb8e759e 8558ebb4 2feef8d2  e22d591 3b0be402 918be1e4 f7925cbd 44f2e4b1 6e2cc049 b97d4708 b1a5da75 f54011da d54471d5 a469e35e 976c3325 b1bd1e46 e29f43db 9eb850e2 f29e860c 358701ea 6a30d870 84b9594c cc2b360d 76ceff11 b7ad905c 68b9066f 5504ed27 ad421538 d83b5b39 3d1f8f03 2ab8f38e 2c2be78d 2823cc75 16d2f044 44f5f685 37bf1702 412b1640 bbb809ae 5fd56b6a fea87a9a ae306a61  a55553c e5b0d09f 1a55af47 dc401931 da0e4580 28c8d6f6 f449fb24 e12c2e76 3175d76c 6c2f18ca c2c93af7 1f462d43 fec71b48 dc997500 33c9f137 

//=== test_modExp_8192bit ===
//m_residue_2_2N_array N:  8224
//m_residue_2_2N_array M:          0 86ad85ba 6b9fa483 25cb106f cf6cc989 911b28f0 1ffd3ef8 30a310db 8851dea4  b16eba5 7cb2e8a5 86729373 37af6f23 81fd1e6c 3372378b f96a2650 42e123b5 8bd46899  279f2de 86af6d84 fbb68d9c 5eba0c14 d07f668d 540bb4e3 fc6fe1ef e7200b10 3e83851d 840bc907 b02a53e4 2ce98544 f1c2ed89  393d845 8798af50 b643566f b883f180 1bc13e4c 65313872 14407175 97edfde2 9cae23ed 6c191326 60ca5eef 8a20b205 36d3ae1b 2829a6a1 441eb400 1a64097f 7827120d d5aee730 b9e4db3e  8f37694 dd13ae34 61d7d990 da0823d5 998f3344 9d8f2c46 50e9d076 e9ad6206 2a34f3be afb54011 c6c900ba c0926836 6bd8966c 7eb44909 6423d068 e1ebaeeb  5b5fbae 5af4fcf8 47fd9f34 324399e0 72713885 e5ed289d df5a4c2a 34b5eccd 730d6ed4 c06298b2 464aa3ac ab97b92f f3561b0c 26d1befa 9b544063 74a2a891 3718a88c 3362334d 7897391f e113b4a8 721a812b 13de3112 d5c9d07c 825d00fd c551ffcb e3872dad  ea2ddda 30e38a98 eee886f2 851272ee 26ed493e 761a0a42  977f9ae 15e99d35 3a58c7f1 bb853700 92981d45 fcf005fa c903f974 d6fe5d06 7797ef09 39dfe6dc ca778773 23cd8208 3794432b e9b52bd1 669dcc76 7d9ff81b 4edf9564 461bb932 385c3cf1 6d3aa7f6 68d5ed7f f5c27db4 e462abe6  84882a1 9af14607 3e2dd725 c4d64037 4f94b5d1 240cca02 4b3d4712 8542f595 f6986ece f8128c0c c27dfe0f f50304fd 6fe1d3a2 5c15ed8e 56064f73 12bdd761 4ef0c5a3 b8b824cf 5457bf8e f2fab63c 8745942a 530d5e8e fd2d1021 d50cd0ee 45e20599 d956c899 71a645c8 24e74ebc   d5f9d6 4b47d99b 819dc9ac 436d92b9 275d6a87 3759de7e 51f82a9f 5fb77a15 6827054f fec842d5  773368c 6b810eff ac47d454 1a3f95b2 3ee49234 4470a046 422e7e36 7199d74b 62d86cc5 17fb0854 8bc0fcb3 98f67476 a07f8ed0 dd806115 a4452b91 3547baba d3bc5863 6566a635 cb23a642 d68a4a15 785e4c3d 9dc9213b 61a305ec 5538dcf2 8050cd48 e51a0e50 f0944155 7245b749 789cca13 b3eef27d 876c4376 2d00d6cf 23236bcf 36459a1a 2f18e804  a7e718f d28ac0c5 b2117e58 7fd9fa32 a2d7c121 403bcc30 82687fb3 9a83289f f7e81754 182256c7 212e1645 7d288176 94b8f048 b406bec1 6685ee15  5d56a42 14123af9 8476b256 d72ffb48 5086084b 32c15f36 805bcf3f a225ac8a b825bb8e 47f51176 3083266e b900bdc7 7fc8517a 7d0533b7 d1c68c2c aee40865 cb17d36e e485ac11 133658cd b07cb8f0 bc27214b eb97236f 46a681aa 5ca3229c febc4116 344f278a 89c29539 1bf5c5fe 37401509 6dba5477 8d46f438 7ae51ee4 537fd502  f69fa4e a2f58c00 1a6fbf0a 54bfbcb8  3c63af0 3ce5dee1 1d74764c 75643806 6918820d aed8caf6  9e78f1f 487758c9 92af5ec8 8eaf83c9 924dc0eb 
//m_residue_2_2N_array Nr:         0 7a208e1a 4b3b8298 e46a15e8 3c4f7945 e53db84e 7ff2678e 76e07a85 d68923d3 f8107779 3d1e2643 4a401c50 112a26f8 8c8c1996 fc4bd3b0 8710f5d8 56e29679 8fa51b8d 78e880ba de954d37 d09dc1bf eb192991 2d51f26f acfb883d db975349 13166f21 ca4549da 9dd09b10 77c2458b 1b2e3b20 20fe824b 9052c645 2f154e74 b1e0151f ec9735b2 1991c577 a446a7d3 3ba6a681 ea980129 9e4ed27d 2b7ac25e b028278c 10d6f810 eec56ad5 a83f99ed 1e3ff9fb fa9bf439 276f1b91 5c68e785 986da263 d35f98ef 632e1ad5 6c489e12 120dab14 3514044b 915309c8 62542a3e f3044eef 89549aaf 5163d741  f5775bd e880b420 805e3aed 32ba1151 79966f35 c9a58f08 1dbb193b b8eebf81 a06e10c3 73d3999c 2d96803d cf471d63 976e711c 3def600e 82782093 cf381559 ee6e1a62 290d0a01 cad42195 f5f2b498 6222f677 669671c9 29246b7b  f6ab6aa a2557ba0 6d69181c 98ebb3c9 4c841256 569867ba 91b394d6 35bbffd8 a96978ea  f99955a 687b881c 88cf7869 fe40a4a5 a242dbc3 d144e8ff e4d14218 cec2bc89 f430adbe d5f2d7d6 7d23be63 f71018d8 c57ff8b8 d1c5a9f2 d313567b  be82f18 6fc6f15d 1be5364a acfc6ca4 39848dcc 5a7e7730  65bcc8a 92552f45  e1e7dfc 57fac240 fb9a5092  5f4876b 33f7375d a9582950 2e1d884b 165b24f1 9a20cd4e 298e476d d5056a97 6cb2f959 fd2ec3e6 797b71df 767644d1 e4395681 29de107e 734ef704 94d0f6dd 6b255306 c8fd34ac e59a18c9 f55e2b7b d75f40a0 20fb4d7f 86a4a71c 885410d8 93d2c568 c03a11b0 4379f46c eb09897a 9a32f5c6 3f9d3e24 1c5cab89 fe47234e 8108fcec 7ff6f72a  945e42a 8ff89adf 91fd98dc b4b12054 95081a3d dd565bce b2cf23bd  f55729f 3fde6399 35fe0c35   c30cd7 5a877b32 ef7b00a8 f46b0b42 94e6547f d21ee495 b6bf32ee 3c2c756f 7b13992d fe48771f bd463618 f5e51159 96ee9990 3ba4ef0b fa4b67dd fae5c654 c59adde7 8ca017ed cd3cdaca 3ad3eae5 61dcab81 b9111fda c5fcf691 c84babad 92f459f5 f0949b76 a357c4dd 5da5f12c c31a0937 6537ac7d e1b964ac f6d6a46d 507ccf8b ce231076 178e3ef6  df6280f 51e25927 cece4c2f  5f44186 5d82132a f1ce8fc4  75ec0a6 2d007172 7cec9468 3fbbbc68 9292a37d dc77c193 856e40b0 7c48db84 bd3cb2fc e15dd891 7f02b6b8 122fd537 517792e6  4b602d6 eeb4079d de6f9a2e cd0f5fb7 c574d9ca 73410863  71fd14d 8d006306 21c6f56c 768063a2 a011ce62 4bf242f8 6400911d b10ec8fb eb70eee8 b314f78b 222990ca 9c41e279 87d7958b 905f460d a4f7672c 443e0bca 346ba6bd 600db86f 1eb8c052 b7ef18d2 ac4d22cc  f44c2f1 666e3248 1f4a4bc5 5baea9fd c1146092 98ac45d6 610ebe98 31c9018a 53c6fcb3 5265fc45 d57f13d1 4d0fa074 451700e9 ae5e77d1 


    $display("   -- Testbench for residue done. --");
    $display(" tests success: %d", test_residue_success);
    $display(" tests failed:  %d", test_residue_fail);
    $finish;
  end // residue tests
endmodule // tb_residue

//======================================================================
// EOF tb_residue.v
//======================================================================









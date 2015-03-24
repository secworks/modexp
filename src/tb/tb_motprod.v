
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
    tb_opa_data = tb_a[tb_opa_addr];
    tb_opb_data = tb_b[tb_opb_addr];
    tb_opm_data = tb_m[tb_opm_addr];
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
      for (i=32'h0; i<256; i=i+1)
        begin
          j = {i, 5'h0};
          tb_a[i] = a[j +: 32];
          tb_b[i] = b[j +: 32];
          tb_m[i] = m[j +: 32];
          tb_r[i] = 32'h0;
          $display("*** init %0x: a: %x b: %x m: %x r: %x", i, tb_a[i], tb_b[i], tb_m[i], tb_r[i]);
        end
    end
    $display("*** test vector copied");
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
          $display("offset: %d expected %x actual %x", i, expected[j +: 32], tb_r[i]); 
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
    test_mont_prod( 1, {32'hb, 8160'h0}, {32'h2, 8160'h0}, {32'h13,8160'h0}, {32'h5,8160'h0} ); 
//* A= 11 B=  b M= 13 A*B= 10 Ar=  7 Br=  9 Ar*Br=  1 A*B= 10
    test_mont_prod( 1, {32'h7, 8160'h0}, {32'h9, 8160'h0}, {32'h13,8160'h0}, {32'h1,8160'h0} ); 
//* A= 11 B= 13 M=  b A*B=  4 Ar=  2 Br=  a Ar*Br=  5 A*B=  4
    test_mont_prod( 1, {32'h2, 8160'h0}, {32'ha, 8160'h0}, {32'h13,8160'h0}, {32'h5,8160'h0} ); 
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

    $display("   -- Testbench for montprod done. --");
    $display(" tests success: %d", test_mont_prod_success);
    $display(" tests failed:  %d", test_mont_prod_fail);
    $finish;
  end // montprod
endmodule // tb_montprod

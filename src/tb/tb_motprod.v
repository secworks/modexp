
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

always @*
  begin : read_test_memory
    tb_opa_data = tb_a[tb_opa_addr];
    tb_opb_data = tb_a[tb_opb_addr];
    tb_opm_data = tb_a[tb_opm_addr];
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
    while (tb_ready == 0)
      #(2 * CLK_HALF_PERIOD);
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
//----------------------------------------------------------------
task test_mont_prod(
    input [0 : 8192-1] a, 
    input [0 : 8192-1] b, 
    input [0 : 8192-1] m,
    input [0 : 8192-1] expected
  );
  begin
    $display("*** test started");
    begin: copy_test_vectors
      integer i;
      for (i=0; i<8192; i=i+32)
        begin
          tb_a[i] = a[i +: 32];
          tb_b[i] = b[i +: 32];
          tb_m[i] = m[i +: 32];
          tb_r[i] = 0;
        end
    end
    $display("*** test vector copied");
    wait_ready();
    signal_calculate();
    wait_ready();
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

    $display("   -- Testbench for montprod done. --");
    $finish;
  end // montprod
endmodule // tb_montprod

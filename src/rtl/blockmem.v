//======================================================================
// mem.v
// -----
// Test synch memory with different widths for API and internal if.
//======================================================================

module blockmem(
                input wire           clk,

                input wire  [07 : 0] read_addr,
                output wire [31 : 0] read_data,

                input wire           wr,
                input wire  [07 : 0] write_addr,
                input wire  [31 : 0] write_data
               );


  //----------------------------------------------------------------
  // Regs and memories.
  //----------------------------------------------------------------
  reg [31 : 0] mem [0 : 255];


  //----------------------------------------------------------------
  // Reg updates.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin : reg_mem
      if (wr)
        mem[write_addr] <= write_data;

      read_data <= mem[read_addr];
    end
endmodule // mem

//======================================================================
// eof mem.v
//======================================================================

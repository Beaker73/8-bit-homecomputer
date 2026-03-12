`ifndef ROM_SV
`define ROM_SV

module Rom(
  input clk, rst,
  input cs,
  input [15:0] addr,
  output [7:0] data
);

  reg [7:0] mem[0:65535];
  assign data = cs ? mem[addr] : 8'bz; 
  
  initial begin
`ifdef EXT_INLINE_ASM
    mem = '{
      __asm

.arch bkr8
.org 0
.len 65536

      push r3
      ld sp, r3

      __endasm
    };
`endif
  end

endmodule;

`endif // ROM_SV
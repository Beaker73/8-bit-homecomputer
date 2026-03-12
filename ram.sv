`ifndef RAM_SV
`define RAM_SV

module Ram(
  input clk, rst, // clock, reset
  input cs, we, // chip select, write enable
  input [A-1:0] address,
  inout [D-1:0] data
);

  parameter A = 14;
  parameter D = 8;
  
  reg [D-1:0] mem [0:(1<<A)-1];
  
  // default output is non-driven
  wire [D-1:0] dataOut;
  
  integer i;
  initial begin
    for(i = 0; i < (1<<A)-1; i = i + 1)
      mem[i] = 0;
  end
  
  // take input, or set output, only when CS (chip select) is set
  always @(posedge clk) begin
    if (cs) begin
      if (we)
        mem[address] <= data;
      else
        dataOut <= mem[address];
    end
  end

  assign data = (cs && !we) ? dataOut : {D{1'bz}};

endmodule;

`endif // RAM_SV
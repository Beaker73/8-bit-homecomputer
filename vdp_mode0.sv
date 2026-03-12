`ifndef VDP_SV_MODE_0
`define VDP_SV_MODE_0

module VdpMode0(
  input clk, rst, enable,
  input [7:0] background,
  input [7:0] border,
  input fg,
  output [7:0] rgb
);

  assign rgb = fg ? background : border; 
  
endmodule;

`endif // vdp mode 0
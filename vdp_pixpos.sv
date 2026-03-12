`ifndef VDP_PIXPOS_SV
`define VDP_PIXPOS_SV

module PixPos(
  input clk, rst,
  input [8:0]hPos,
  input [8:0]vPos,
  input signed [3:0] xAdj,
  input signed [3:0] yAdj,
  output reg signed [9:0]xPos,
  output reg signed [9:0]yPos,
  output reg fg
);

  assign xPos = { 1'b0, hPos } - 18 - {{6{xAdj[3]}}, xAdj};
  assign yPos = { 1'b0, vPos } - 24 - {{6{yAdj[3]}}, yAdj};
  assign fg = xPos >= 0 && xPos < 256 && yPos >= 0 && yPos < 208;
	
endmodule;

function [7:0] createPixPos;
  input signed [3:0] x;
  input signed [3:0] y;
begin
  createPixPos = { x, y };
end
endfunction;


`endif // vdp pixel position


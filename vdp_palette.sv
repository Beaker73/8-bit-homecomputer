`ifndef VDP_PALETTE_SV
`define VDP_PALETTE_SV

`include "rgb.sv"

module Palette(
  input [1:0] palette,
  input [3:0] index,
  output [7:0] rgb
);

  reg [7:0] colors [0:3][0:15];
  
  initial begin
    colors[0][0] = createRgb(0,0,0);
    colors[0][1] = createRgb(0,0,0); // 1: black
    colors[0][2] = createRgb(2,2,1);
    colors[0][3] = createRgb(5,5,2);
    colors[0][4] = createRgb(7,7,3); // 4: white
    colors[0][5] = createRgb(7,1,0);
    colors[0][6] = createRgb(7,3,0);
    colors[0][7] = createRgb(7,7,0);
    colors[0][8] = createRgb(0,5,0);
    colors[0][9] = createRgb(0,3,0);
    colors[0][10] = createRgb(0,6,3); // 10: cyan
    colors[0][11] = createRgb(0,2,3);
    colors[0][12] = createRgb(0,0,2);
    colors[0][13] = createRgb(4,0,2);
    colors[0][14] = createRgb(4,2,0);
    colors[0][15] = createRgb(7,5,2);
  end
  
  always @* begin
    rgb = colors[palette][index];
  end
  
endmodule;

`endif // vdp pixel position


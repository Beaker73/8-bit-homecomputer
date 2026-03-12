`ifndef RGB_SV
`define RGB_SV

function [7:0] createRgb;
  input [2:0] r;
  input [2:0] g;
  input [1:0] b;
begin
  createRgb = {r, g, b}; 
end
endfunction

function [2:0] getR;
  input [7:0] rgb;
begin
  getR = rgb[7:5];
end
endfunction

function [2:0] getG;
  input [7:0] rgb;
begin
  getG = rgb[4:2];
end
endfunction

function [1:0] getB;
  input [7:0] rgb;
begin
  getB = rgb[1:0];
end
endfunction


`endif // RGB_SV
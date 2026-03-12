`ifndef VDP_SV_MODE_1
`define VDP_SV_MODE_1

module VdpMode1(
  input clk, rst, enable,
  input signed [9:0] xPos,
  input signed [9:0] yPos,
  input [7:0] border,
  input fg,
  input [7:0] addrPixel,
  output read,
  output [16:0] addr,
  input [7:0] data,
  output [7:0] rgb
);

  wire signed [9:0] sxPos = xPos + 1;
  assign addr = { addrPixel, 9'd0 } + { yPos[7:0], sxPos[7:0] };
  
  always @(posedge clk) begin
    
    if(fg) begin
      // when shifted pos is inside visible area 
      // request byte data
      if(sxPos[9:8] == 2'b00) begin
        read <= 1;
      end

      if(xPos[9:8] == 2'b00) begin
        rgb <= data;
      end
      
    end else begin
      rgb <= border;
    end
    
  end
  
endmodule;

`endif // vdp mode 1
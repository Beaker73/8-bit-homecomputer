`ifndef SYNC_SV
`define SYNC_SV

module Sync(
  input clk, rst,
  output hsync, vsync,
  output reg [8:0] hpos,
  output reg [8:0] vpos
);
  
  localparam CLOCK = 4857480;
  localparam FPS = 60;
  localparam LINES = 262;
  localparam FRAME_TICKS = CLOCK / FPS; // 80958
  localparam LINE_TICKS = FRAME_TICKS / LINES; // 309
  localparam H_SYNC_TICKS = 23;
  localparam V_SYNC_LINES = 4; 
  
  always @(posedge clk) begin
    if(rst) begin
      hpos <= 0;
      vpos <= 0;
    end
    else
    begin

      // go to next line at end
      if(hpos >= 9'(LINE_TICKS-1)) begin
        hpos <= 0;
        
        // go to next frame at end
        if(vpos >= 9'(LINES-1)) begin
          vpos <= 0;
        end else begin
	  vpos <= vpos + 1;
        end
      end else begin
        hpos <= hpos + 1;
      end
    end
  end
  
  // enable hsync signal 23 ticks before end of line
  assign hsync = hpos >= 9'(LINE_TICKS - H_SYNC_TICKS);
  // enable vsync signal 4 lines before end of frame
  assign vsync = vpos >= 9'(LINES - V_SYNC_LINES);
  
  
endmodule;

`endif // sync
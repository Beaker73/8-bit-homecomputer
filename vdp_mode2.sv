`ifndef VDP_SV_MODE_2
`define VDP_SV_MODE_2

module VdpMode2(
  input clk, rst, enable,
  input signed [9:0] xPos,
  input signed [9:0] yPos,
  input [7:0] border,
  input [7:0] background,
  input [7:0] foreground,
  input noColor,
  input fg,
  input [7:0] addrChar,    // character (text on screen): ASCII char per byte, 40*24
  input [7:0] addrColor,   // color (color of text) format: BBBBFFFF per char
  input [7:0] addrPat,     // pattern (patterns of chars): 8bytes per char
  input [7:0] addrPalette, // palette (palette configuration per color): 16 RRRGGGBB colors
  output read_out,
  output [16:0] addr_out,
  input [7:0] data,
  output [7:0] rgb
);
  
  /**
  	we have 6 cycles per char
        
        0: read char (byte)
        1: read color (bbbbffff)
        2: read pattern based on Y line (1 byte from 8 bytes)
        3: read palette foreground (rrrgggbb)
        4: read palette background (rrrgggbb)
        5: -unused-
  **/
  

  wire signed [9:0] sxPos = xPos + 6; // we fetch 1 char (6 pixels/cycles) before the output

  /**************
  ** cycle counter (otherwise we need to do a module 6)
  ***************/

  // the current cycle inside the fetch
  // we use a counter since this screen uses chars that are 6 pixels, not 8.
  reg [2:0] addr_cycle;  // cycle for address generation
  reg [2:0] data_cycle;  // cycle for data processing (1 cycle behind addr_cycle)
  reg [5:0] col;
  
  /* keep track of cycles (0-5) */
  always @(posedge clk) begin
    if(enable) begin
      if(sxPos == 10'd0) begin
        addr_cycle <= 0;
        data_cycle <= 5;  // data_cycle lags behind addr_cycle by 1 (memory latency)
        col <= 6'd0;
      end else begin
        
        if(addr_cycle == 5) begin
          addr_cycle <= 0;
          col <= col + 1;
        end
        else
          addr_cycle <= addr_cycle + 1;
          
        if(data_cycle == 5)
          data_cycle <= 0;
        else
          data_cycle <= data_cycle + 1;
      end
    end
  end

  /**************
  ** request data (in this cycle)
  ***************/

  reg [16:0] addr;
  reg read;
  wire canRead = enable
    && sxPos[9:8] == 2'b00  // x must be positive and in range of 0-256
    && sxPos < 252          // and less then 252, since we have 4 pixels remaining (256/6 = 42 and 4r)
    && yPos[9:8] == 2'b00   // y must be positive and in range of 0-256
    && yPos < 208;          // y must be < 208, 26 rows of 8 lines.
  
  always @* begin
    if(canRead) begin
      case(addr_cycle)
        
        3'd0: begin 	
          // request character
          addr = { addrChar, 3'd0, col } + m2mult42(yPos[7:3]);
          read = 1;
        end

        3'd1: begin
          // request colors for char
          addr = { addrColor, 3'd0, col } + m2mult42(yPos[7:3]);
          read = 1;
        end

        3'd2: begin
          // request pattern of char for this line
          addr = { addrPat, 9'd0 } + { 6'd0, char, yPos[2:0] };
          read = 1;
        end

        3'd3: begin
          // request palette for foreground color
          addr = { addrPalette, 5'd0, charForeground };
          read = 1;
        end

        3'd4: begin
          // request palette for background color
          addr = { addrPalette, 5'd0, charBackground };
          read = 1;
        end
        
        3'd5: begin
          addr = 0;
          read = 1; // why do we need to keep read one cycle longer active; otheriwise background palette data is missing (cycle 4 data) ?
        end
        
        default: begin
          addr = 17'd0;
          read = 1'd0;
        end

      endcase
    end else begin
      addr = 17'd0;
      read = 1'd0;
    end
  end
 
  assign addr_out = addr;
  assign read_out = canRead && read;

  /**************
  ** fetch data (on next cycle)
  ***************/

  reg [7:0] char;
  reg [3:0] charForeground;
  reg [3:0] charBackground;
  reg [7:0] pattern, ptn;
  reg [7:0] paletteForeground, pfg;
  reg [7:0] paletteBackground, pbg;

  wire canStore = enable
    && sxPos[9:8] == 2'b00  // x must be positive and in range of 0-256
    && sxPos > 0	    // and +1
    && sxPos < (252+2)          // and less then 252+1, since we have 4 pixels remaining (256/6 = 42 and 4r)
    && yPos[9:8] == 2'b00   // y must be positive and in range of 0-256
    && yPos < 208;          // y must be < 208, 26 rows of 8 lines.

  always @(posedge clk) begin
    if(canStore) begin

      // when shifted pos is inside visible area 
      // request byte data
      case(data_cycle)  // use data_cycle for data processing

        3'd0: begin
          // store incoming character
          char <= data;
        end

        3'd1: begin
          // store incoming color info
          charBackground <= data[7:4];
          charForeground <= data[3:0];
        end

        3'd2: begin
          // store pattern for this line
          pattern <= data;
        end

        3'd3: begin
          // store foreground palette
          paletteForeground <= noColor ? foreground : data;
        end

        3'd4: begin
          // store background palette
          paletteBackground <= noColor || charBackground == 4'd0 ? background : data;
        end
        
        default: begin
          // copy over data to the next buffer, because
          // we will be getting the next bytes during the outputting these values
          // (effectivly this is a 2 stage pipeline, where each stage is 6 cycles long)
          ptn <= pattern;
          pbg <= paletteBackground;
          pfg <= paletteForeground;
        end
        
      endcase
    end
  end
  
  // determine which bit of the pattern to use for current pixel
  // swap bit order, since scanline goes from left to right > msb to lsb > 7 to 2
  // but also we are another cycle shift since we are linked to clock
  wire [2:0] pixel = 7 - data_cycle;
  wire canOutput = enable
    && xPos[9:8] == 2'b00   // x must be positive and in range of 0-256
    && xPos >= 2	    // add 2 extra pixles (we have 4 remainging, to correctly center we add 2 extra pixels)
    && xPos < (252 + 2)     // and less then 252, since we have 4 pixels remaining (256/6 = 42 and 4r)
    && yPos[9:8] == 2'b00   // y must be positive and in range of 0-256
    && yPos < 208;          // y must be < 208, 26 rows of 8 lines.
  
  /* process stored data to ouput pixel */
  always @(posedge clk) begin
    if(canOutput)
      rgb <= ptn[pixel] ? pfg : pbg;
    else
      rgb <= border;
  end
  
 
endmodule;

function [16:0] m2mult42;
  input [4:0] value;
  // value*32 + value*8 + value*2
  m2mult42 = ({12'd0, value} << 5) + ({12'd0, value} << 3) + ({12'd0, value} << 1);
endfunction

`endif // vdp mode 2

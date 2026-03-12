`ifndef VDP_SPRITES_SV
`define VDP_SPRITES_SV

enum {
  SPRBUF_YPOS,
  SPRBUF_XPOS,
  SPRBUF_TILE0,
  SPRBUF_TILE1,
  SPRBUF_DATA00,
  SPRBUF_DATA01,
  SPRBUF_DATA10,
  SPRBUF_DATA11
} t_sprbuf;

module Sprites(
  input clk, rst, enable,
  input signed [9:0] xPos,
  input signed [9:0] yPos,
  input [16:9] addrSpriteMetadataH,
  input [16:9] addrSpriteTilesH,
  input [16:9] addrPaletteH,
  output read,
  output [16:0] address,
  input [7:0] data,
  output render,
  output [7:0] rgb
);

  
  
  // 53 bytes max
  
  
  // streaming data (max 53 cycles/bytes)
  // 1  byte  ypos
  // 1  byte  xpos
  // 2  bytes of tile indexes
  // 4  bytes data (2 per tile)
  // 1  byte palette index
  // 3  bytes of palette data
  // 12
  // 53 / 12 = max 4 sprites
  
  // metadata format
  // 1 xPos
  // 1 yPos
  // 4 tile indexes
  // 1 palette index     3  2  1  0
  // 1 flip bitfields - xy xy xy xy
  reg [7:0] buffer[4][8];
  
  reg access;
  reg [5:0] cycle;
  reg [1:0] sprIndex;
  reg [3:0] sprCycle;
  always @(posedge clk) begin
    
    if(enable) begin
      
    // when last pixel of line, start sprite cycle
    // 2 cycles before start compute index
    if (yPos >= -1 && yPos < 211 && xPos == 255) begin
      access <= 1;
      cycle <= 0;
      sprIndex <= 0;
      sprCycle <= 0;
    end

    // when access cycle then count the positions
    // 4 sprite cycles of 12 cycles each
    if(access) begin
      cycle <= cycle + 1;
      read <= 1;
      
      if (sprCycle < 11)
        sprCycle <= sprCycle + 1;
      else begin
        sprCycle <= 0;
        if(sprIndex < 3)
          sprIndex <= sprIndex + 1;
        else begin
          access <= 0;
          read <= 0;
        end
      end
      
      case (sprCycle)
        
        0: begin
          // read y address
          address <= { addrSpriteMetadataH, 2'd0, sprCycle, 3'd1 };
        end
        
        1: begin
          // store y address for sprite
          buffer[sprIndex][SPRBUF_YPOS] <= data;
          if(data != 255) begin
            // read x address
            address <= { addrSpriteMetadataH, 2'd0, sprCycle, 3'd0 };
          end
        end
        
        2: if(buffer[sprIndex][SPRBUF_YPOS] != 255) begin
          // store x address for sprite
          buffer[sprIndex][SPRBUF_XPOS] <= data;
          // need first or thirth tile index
          address <= (yPos < {2'b00, 8'(buffer[sprIndex][SPRBUF_YPOS] + 8'd8)})
            ? { addrSpriteMetadataH, 2'd0, sprCycle, 3'd2 }
            : { addrSpriteMetadataH, 2'd0, sprCycle, 3'd4 };
        end
        
        3: if(buffer[sprIndex][SPRBUF_YPOS] != 255) begin
          // store tile index
          buffer[sprIndex][SPRBUF_TILE0] <= data;
          // need second or firth tile index
          address <= (yPos < {2'b00, 8'(buffer[sprIndex][SPRBUF_YPOS] + 8'd8)})
            ? { addrSpriteMetadataH, 2'd0, sprCycle, 3'd3 }
            : { addrSpriteMetadataH, 2'd0, sprCycle, 3'd5 };
        end
        
        4: if(buffer[sprIndex][SPRBUF_YPOS] != 255) begin
          // store tile index
          buffer[sprIndex][SPRBUF_TILE1] <= data;
          // start reading first half of tile 0
          address <= { 
            addrSpriteTilesH, 1'd0, 
            sprCycle, 
            (yPos < {2'b00, (buffer[sprIndex][SPRBUF_YPOS] + 8'd8)})
            ? {(yPos - {2'b00, 8'(buffer[sprIndex][SPRBUF_YPOS])})}[2:0]
            : {(yPos - {2'b00, 8'(buffer[sprIndex][SPRBUF_YPOS] - 8'd8)})}[2:0],
            1'b0
          };
        end
        
        5: if(buffer[sprIndex][SPRBUF_YPOS] != 255) begin
          // store tile data 00
          buffer[sprIndex][SPRBUF_DATA00] <= data;
          // start reading second half of tile 0
          address <= { 
            addrSpriteTilesH, 1'd0, 
            sprCycle, 
            (yPos < {2'b00, (buffer[sprIndex][SPRBUF_YPOS] + 8'd8)})
              ? {(yPos - {2'b00, 8'(buffer[sprIndex][SPRBUF_YPOS])})}[2:0]
              : {(yPos - {2'b00, 8'(buffer[sprIndex][SPRBUF_YPOS] - 8'd8)})}[2:0],
            1'b1
          };
        end
        
      endcase
      
    end 
      
    end
    
  end
  
  assign render = enable && access;
  assign rgb = createRgb(sprCycle[3:1], { 1'b0, sprIndex }, 0);
  
endmodule;

`endif // VDP_SPRITES_SV
`ifndef VDP_SV
`define VDP_SV

`include "rgb.sv"

`include "vram.sv"
`include "sync.sv"
`include "vdp_palette.sv"
`include "vdp_pixpos.sv"
`include "vdp_mode0.sv"
`include "vdp_mode1.sv"
`include "vdp_mode2.sv"
`include "vdp_sprites.sv"

enum {
  REG_MODE,
  REG_FLAGS,
  REG_BG_COLOR,
  REG_BDR_COLOR,
  REG_FG_COLOR,
  REG_PIXPOS,
  REG_ADDR_CHAR_H,
  REG_ADDR_PIXEL_H,
  REG_ADDR_COLOR_H,
  REG_ADDR_PALETTE_H,
  REG_ADDR_SPRITE_META_H,
  REG_ADDR_SPRITE_TILE_H,
  REG_ADDR_
} t_regs;

module Vdp(
  input clk, rst,
  output hsync, vsync,
  output [7:0] rgb
);
  
  wire [8:0] hpos;
  wire [8:0] vpos;
  
  reg [7:0] regs [16];
  
  always @(posedge clk) begin
    if (rst) begin
      regs[REG_MODE] <= 2; // 0 - Null; 1 - 256color; 2 - Text 40; 3 - 32x26 Tiled
      regs[REG_FLAGS] <= 8'b00000010; //  0=Sprites, 1=NoColor (mode2)
      regs[REG_BG_COLOR] <= { 2'd0, 2'd0, 4'd0 };
      regs[REG_BDR_COLOR] <= { 2'd0, 2'd0, 4'd12 };
      regs[REG_FG_COLOR] <= { 2'd0, 2'd0, 4'd4 };
      regs[REG_PIXPOS] <= createPixPos(0, 0);
      /** 1 **/
      // regs[REG_ADDR_PIXEL_H]  		<= {17'h00000}[16:9];
      /** 2 **/
      regs[REG_ADDR_CHAR_H]		<= {17'h04000}[16:9];
      regs[REG_ADDR_PIXEL_H]  		<= {17'h05000}[16:9];
      regs[REG_ADDR_COLOR_H]  		<= {17'h06000}[16:9];
      regs[REG_ADDR_SPRITE_META_H]	<= {17'h10000}[16:9];
      regs[REG_ADDR_SPRITE_TILE_H]	<= {17'h11000}[16:9];
      regs[REG_ADDR_PALETTE_H]		<= {17'h0f000}[16:9];
    end
  end
  
  wire spritesEnabled = regs[REG_FLAGS][0];
  wire noColor = regs[REG_FLAGS][1];
   
  wire [7:0] data;
  wire [16:0] address;
  wire read;
  VRam ram(
    .clk(clk), .rst(rst),
    .cs(read),
    .we(0),
    .address(address),
    .data(data)
  );
  
  Sync sync(
    .clk(clk), .rst(rst),
    .hsync(hsync), .vsync(vsync),
    .hpos(hpos), .vpos(vpos)
  );
  
  wire signed [9:0] xPos;
  wire signed [9:0] yPos;
  wire fg;
  PixPos pixPos(
    .clk(clk), .rst(rst),
    .hPos(hpos), .vPos(vpos),
    .xAdj(regs[REG_PIXPOS][7:4]),
    .yAdj(regs[REG_PIXPOS][3:0]),
    .xPos(xPos), .yPos(yPos),
    .fg(fg)
  ); 
  
  wire isMode0 = regs[REG_MODE] == 0;
  wire [7:0]rgb0;
  VdpMode0 mode0(
    .clk(clk), .rst(rst),
    .enable(isMode0),
    .background(regs[REG_BG_COLOR]),
    .border(regs[REG_BDR_COLOR]),
    .fg(fg),
    .rgb(rgb0)
  );
  
  wire isMode1 = regs[REG_MODE] == 1;
  wire [7:0] rgb1;
  wire read1;
  wire [16:0] address1;
  VdpMode1 mode1(
    .clk(clk), .rst(rst),
    .enable(isMode1),
    .xPos(xPos), .yPos(yPos),
    .border(regs[REG_BDR_COLOR]),
    .fg(fg),
    .addrPixel(regs[REG_ADDR_PIXEL_H]),
    .read(read1),
    .addr(address1),
    .data(data),
    .rgb(rgb1)
  );
  
  wire isMode2 = regs[REG_MODE] == 2;
  wire [3:0] index2;
  wire read2;
  wire [16:0] address2;
  VdpMode2 mode2(
    .clk(clk), .rst(rst),
    .enable(isMode2),
    .xPos(xPos), .yPos(yPos),
    .border({regs[REG_BDR_COLOR]}[5:0]),
    .background({regs[REG_BG_COLOR]}[5:0]),
    .foreground({regs[REG_FG_COLOR]}[5:0]),
    .noColor(noColor),
    .addrChar(regs[REG_ADDR_CHAR_H]),
    .addrColor(regs[REG_ADDR_COLOR_H]),
    .addrPat(regs[REG_ADDR_PIXEL_H]),
    .read_out(read2),
    .addr_out(address2),
    .data(data),
    .index(index2)
  );
  
  wire isMode3 = regs[REG_MODE] == 3;
  wire [7:0] rgb3;
  wire read3;
  wire [16:0] address3;
  VdpMode3 mode3(
    .clk(clk), .rst(rst),
    .enable(isMode3),
    .xPos(xPos), .yPos(yPos),
    .tileAddr(regs[REG_ADDR_CHAR_H]),
    .patAddr(regs[REG_ADDR_PIXEL_H]),
    .read_out(read3),
    .addr_out(address3),
    .data(data),
    .rgb(rgb3)
  ); 
  
  wire reads;
  wire [7:0] rgbs;
  wire renderSprite = 0;
  wire [16:0] addresss;
  Sprites sprites(
    .clk(clk), .rst(rst), .enable(spritesEnabled),
    .xPos(xPos), .yPos(yPos),
    .addrSpriteMetadataH(regs[REG_ADDR_SPRITE_META_H]),
    .addrSpriteTilesH(regs[REG_ADDR_SPRITE_TILE_H]),
    .addrPaletteH(regs[REG_ADDR_PALETTE_H]),
    .read(reads),
    .address(addresss),
    .data(data),
    .render(renderSprite), .rgb(rgbs)
  );
  
  /********************
  ** Convert Indexed values to RGB
  ********************/
  
  wire [1:0] palette;
  wire [3:0] index;
  always @* begin
    case(regs[REG_MODE])
      2: begin
        palette = 2'd0;
        index = index2;
      end
      default: begin
        palette = 2'd0;
        index = 4'd0;
      end
    endcase
  end
  
  wire [7:0] rgbp;
  Palette p(
    .palette(palette),
    .index(index),
    .rgb(rgbp)
  );
  
  
  
  wire [7:0] rgbm;
  always @* begin
    
    if(spritesEnabled && reads) begin
      read = reads;
      address = addresss;
    end
    else begin
      case (regs[REG_MODE])

        0: begin
          read = 0;
          address = 0;
          rgbm = rgb0;
        end

        1: begin
          read = read1;
          address = address1;
          rgbm = rgb1;
        end

        2: begin
          read = read2;
          address = address2;
          rgbm = rgbp;
        end

        3: begin
          read = read3;
          address = address3;
          rgbm = rgb3;
        end

        default: begin
          read = 0;
          address = 0;
          rgbm = 0;
        end

      endcase
    end
    
    rgb = (spritesEnabled && renderSprite) ? rgbs : rgbm;
    
  end
  
endmodule

`endif // vdp
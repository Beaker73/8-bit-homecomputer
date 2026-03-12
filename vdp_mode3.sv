`ifndef VDP_SV_MODE_3
`define VDP_SV_MODE_3

module VdpMode3(
  input clk, rst, enable,
  input signed [9:0] xPos,
  input signed [9:0] yPos,
  input [16:9] tileAddr,
  input [16:9] patAddr,
  output read_out,
  output [16:0] addr_out,
  input [7:0] data, 
  output [7:0] rgb  
);
  
  /*
  
   Available per tile: 8 cycles / bytes
   
   0: tile index
   1: flags: prio(1) flipv(1) fliph(1) palette-bank(2)
   2: anim: shifty(2) shiftx(2) size(2) speed(2)
   3: unused for now
   4: pixel 0,1
   5: pixel 2,3
   6: pixel 4,5
   7: pixel 6,7
   
   Tile Data
   
   0: tile index
   1: flags
   2: anim
   3: future
   
   32x26 chars = 832 chars * 4 bytes = 3328 (<4Kb)
   
   Pattern Data:
   
   4bytes * 8 = 32 bytes per tile
   256 tiles * 32 bytes = 8Kb of tile patterns
  
  */
  
  // shifted xPos 8 cycles (1 tile) ahead of actual render
  wire signed [9:0] sxPos = xPos + 8;
  // the cycle number in the byte/tile
  wire [2:0] cycle = sxPos[2:0];
  wire [2:0] tileLine = yPos[2:0];
  // the shifted column number (fetch column)
  wire [4:0] sCol = sxPos[7:3];
  // the shifted row number (fetc row)
  wire [4:0] sRow = yPos[7:3];

  /******************
  ** Request Read
  ******************/
  
  reg read;
  reg [16:0] address;
  
  wire canRead = enable
    && sxPos[9:8] == 2'b00  // x must be positive and in range of 0-256
    && yPos[9:8] == 2'b00   // y must be positive and in range of 0-256
    && yPos < 208;          // y must be < 208, 26 rows of 8 lines.
  
  always @* begin
    if(canRead) begin
      case(cycle)
        0,1,2,3: begin
          address = { tileAddr, 9'b0 } + { 5'b0, sRow, sCol, cycle[1:0] };
          read = 1;
        end
        4,5,6,7: begin
          address = { patAddr, 9'b0 } + { 4'b0, tileIndex, tileLine, cycle[1:0] };
          read = 1;
        end
        default: begin
          read = 0;
          address = 0;
        end
      endcase
    end else begin
      read = 0;
      address = 0;
    end
    
    read_out = read;
    addr_out = address;
  end

  assign read_out = read;
  assign addr_out = address;

  /******************
  ** Read and Buffer
  ******************/
  
  reg [7:0] buffer[8];
  wire [7:0] tileIndex = buffer[0];
  
  always @(posedge clk) begin
    buffer[cycle] <= data;
  end
  
  /******************
  ** Output
  ******************/
  wire [7:0] pat; // pattern
  wire [3:0] pix; // pixel index
  always @* begin
    pat = {buffer[4 + cycle[2:1]]}; // take pat from buffer, 2 cycles, 1 byte (2 nibbles)
    pix = cycle[0] == 1'b0 ? pat[7:4] : pat[3:0]; // take nible from pat
                                 
    rgb = createRgb(pix[3:1], 0, {1'b0, pix[0]});
  end
  
  assign rgb = createRgb(0,0,0);
  
endmodule;

`endif // VDP_SV_MODE_3
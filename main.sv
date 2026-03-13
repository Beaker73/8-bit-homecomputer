// this root serves as the bus / motherboard of the system

`ifndef MAIN_SV
`define MAIN_SV


`include "rgb.sv"

`include "ram.sv"
`include "vram.sv"
`include "rom.sv"
`include "cpu.sv"
`include "sync.sv"

`include "vdp.sv"
`include "vdp_pixpos.sv"
`include "vdp_palette.sv"
`include "vdp_mode0.sv"
`include "vdp_mode1.sv"
`include "vdp_mode2.sv"
`include "vdp_mode3.sv"
`include "vdp_sprites.sv"

`ifdef BKR8
`include "bkr8.json"
`endif

module top 
(
  input clk, reset,
  
  output hsync, vsync,
  output [31:0] rgb,
 
  output [15:0] address,
  output [7:0] data

);

  /***********************
  ** RAM
  ***********************/
  
  // default to 128 pages (1MB)
  parameter RAM_PAGES = 8;
  localparam RAM_BITS = $clog2(RAM_PAGES);

  // ram via a memory mapper

  //wire [15:0] address = 0;
  //wire [7:0] data;
  reg [RAM_BITS:0] pageMap[8]; // MSB 1=ROM 0=RAM
  wire we = 0;
  
  // reset memory mapper
  always @(posedge clk) begin
    if(reset) begin
      pageMap[0] <= { 1'b1, 3'b0 }; // ROM page 0
      pageMap[1] <= 1;
      pageMap[2] <= 2;
      pageMap[3] <= 3;
      pageMap[4] <= 4;
      pageMap[5] <= 5;
      pageMap[6] <= 6;
      pageMap[7] <= 7;
    end
  end

  // extract the current page from the address via the mapping
  wire [RAM_BITS:0] page = pageMap[address[15:13]];

  // RAM
  // for every page
  genvar i;
  generate
    for(i = 0; i < RAM_PAGES; i++) begin: mem    
      
      // determine if this RAM chip is enabled
      wire cs = page[3] == 1'b0 && page[2:0] == i;
      
      // RAM page
      Ram ram(
        .clk(clk), .rst(reset),
        .cs(cs),
        .we(we),
        .address({ 3'0, address[12:0] }),
        .data(data)
      );
    end
  endgenerate
  
  // ROM
  wire rs = page[3] == 1'b1;
  Rom rom(
    .clk(clk), .rst(reset),
    .cs(rs),
    .addr({ page[2:0], address[12:0] }),
    .data(data)
  );

  /***********************
  ** VDP
  ***********************/
  
  wire [7:0] rgb8;
  Vdp vdp(
    .clk(clk), .rst(reset),
    .hsync(hsync), .vsync(vsync),
    .rgb(rgb8)
  );
  
  // convert internal rgb to external rgb
  wire [7:0] r = { getR(rgb8), getR(rgb8), rgb8[7:6] };
  wire [7:0] g = { getG(rgb8), getG(rgb8), rgb8[4:3] };
  wire [7:0] b = { getB(rgb8), getB(rgb8), getB(rgb8), getB(rgb8) };
  assign rgb = { 8'hff, b, g, r };

  /***********************
  ** CPU
  ***********************/

  wire read, write;
  
  Cpu cpu(
    .clk(clk), .rst(reset),
    .read(read), .write(write),
    .address(address),
    .data(data)
  );
  
endmodule

`endif // MAIN_SV
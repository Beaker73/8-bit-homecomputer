`ifndef CPU_SV
`define CPU_SV

typedef enum bit[3:0] { 
  INIT_READ_OPP, READ_OPP, EXEC_OPP
} Mode;

module Cpu(
  input clk, rst,
  output read, write,
  output [15:0]address,
  inout [7:0]data
);

  Mode mode = INIT_READ_OPP;
  
  reg [7:0]opp;
  reg [15:0]r[8];
  reg [7:0] dataOut = 0;
  
  // RESET
  
  always @(posedge clk) begin
    
    if (rst) begin
      address <= 16'b0;
      dataOut <= 8'b0;
      mode <= INIT_READ_OPP;
      r[0] <= 0;
      r[1] <= 0;
      r[2] <= 0;
      r[3] <= 0;
      r[4] <= 0;
      r[5] <= 0;
      r[6] <= 0;
      r[7] <= 0;
    end
    
  end
  
 
  always @(posedge clk) begin

    if (!rst) begin
      case(mode)

        // output PC on address
        // and put bus in read mode
        INIT_READ_OPP: begin
          address <= r[7];
          read <= 1;
          mode <= READ_OPP;
        end

        // read the opcode from the bus
        READ_OPP: begin
          opp <= data;
          r[7] <= r[7] + 1;
          mode <= EXEC_OPP;
        end
        
        EXEC_OPP: begin
          case(opp[7:6])

            // LD Rx,Rx
            00: begin
              r[opp[5:3]] <= r[opp[2:0]];
            end

            default:;

          endcase
        end

        default:;

      endcase
    end
    
  end
  
  assign write = 0;
  assign data = !rst && write ? dataOut : 8'bz;
  
endmodule

`endif // CPU_SV

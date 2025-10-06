`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.10.2025 19:15:53
// Design Name: 
// Module Name: stream_conv1_2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module stream_conv1_2 #(parameter DATA_WIDTH=64,TOTAL_SAMPLES=733824,DEPTH=4096,ACTIVE_SAMPLES=3276,IDLE_CYCLES=1172)(
input clk,resetn,
input s_valid,
input [DATA_WIDTH-1:0] s_data,
output reg s_ready,

output reg [(DATA_WIDTH/2)-1:0] data_port1,
output reg valid1,
output reg [(DATA_WIDTH/2)-1:0] data_port2,
output reg valid2
    );
    
reg [12:0] data_cnt;
reg [10:0] idle_cnt;
reg [DATA_WIDTH-1:0] fifo_out;
reg rd_en;    
    
//fifo parameters
localparam ptr_width = $clog2(DEPTH);
reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1]; // memory array 
reg [ptr_width-1:0] rd_ptr,wr_ptr; // read and write pointers

wire empty = (wr_ptr == rd_ptr);  
wire full  = (wr_ptr+1 == rd_ptr);
    
//assign s_ready = !full;

wire wr_en = (s_valid && s_ready);

always@(*) begin
fifo_out <= fifo_mem[rd_ptr];
end

//FIFO write logic   
always@(posedge clk or negedge resetn)
begin
s_ready = !full;
if(!resetn) begin
    wr_ptr <= 0;
end
    
else begin
if (wr_en) begin
    //Writing data into the FIFO
    fifo_mem[wr_ptr] <= s_data;
    wr_ptr <= wr_ptr + 1 ;      
end
// FIFO read operation
    if(rd_en && !empty) begin
    //fifo_out <= fifo_mem[rd_ptr];
    rd_ptr <= rd_ptr+1;
    data_cnt <= data_cnt+1;
    end 
end

end
// FSM Logic for 3276 ACTIVE + 1172 IDLE pattern
typedef enum logic [1:0] {
START = 2'b00,
ACTIVE = 2'b01,
IDLE = 2'b10
} state_t; 

state_t ps,ns;

// FSM sequential
always@(posedge clk or negedge resetn)
begin
if(!resetn) begin
    ps <= START;
    rd_ptr <= 0;
    data_cnt <= 0;
    idle_cnt <= 0;
    valid1 <= 0;
    valid2 <= 0;
    rd_en <= 0;
    fifo_out <= 0;
    data_port1 <= 0;
    data_port2 <= 0;  
end
else begin
    ps <= ns;
    
    
    case(ps)
    START : begin
            valid1 <= 0;
            valid2 <= 0;
            rd_en <= 0;
            ns <= ACTIVE;
            end
     ACTIVE : begin
              if(!empty) begin
              rd_en <= 1;
              valid1 <= 1;
              valid2 <= 1;
              data_port1 <= fifo_out[31:0];
              data_port2 <= fifo_out[63:32];
              //data_cnt <= data_cnt+1;
              end
              else begin
              valid1 <= 0;
              valid2 <= 0;
              rd_en <= 0;
              end
              
              if(data_cnt == ACTIVE_SAMPLES-1) begin
              s_ready = 0;
              data_cnt <= 0;
              ns <= IDLE;
              end
              end
       IDLE : begin
              valid1 <= 0;
              valid2 <= 0;
              rd_en <= 0;
              s_ready <= 0;
              data_port1 <= 0;
              data_port2 <= 0;
              idle_cnt <= idle_cnt+1;
              
              if(idle_cnt == IDLE_CYCLES-1) begin
              idle_cnt <= 0;
              ns <= ACTIVE;
              end
              end
       endcase
    end
end
endmodule
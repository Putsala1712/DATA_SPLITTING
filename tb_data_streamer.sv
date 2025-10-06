`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.10.2025 22:18:18
// Design Name: 
// Module Name: tb_data_streamer
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


module tb_data_streamer();
parameter DATA_WIDTH=64,TOTAL_SAMPLES=733824,DEPTH=4096,ACTIVE_SAMPLES=3276,IDLE_CYCLES=1172;

reg clk,resetn;
reg s_valid;
reg [DATA_WIDTH-1:0] s_data;
wire s_ready;

wire [(DATA_WIDTH/2)-1:0] data_port1;
wire valid1;
wire [(DATA_WIDTH/2)-1:0] data_port2;
wire valid2;

stream_conv1_2 #(DATA_WIDTH,TOTAL_SAMPLES,DEPTH,ACTIVE_SAMPLES,IDLE_CYCLES) dfgd (clk,resetn,s_valid,s_data,s_ready,data_port1,valid1,data_port2,valid2);

initial clk=0;
always #5 clk=~clk;

// Memory to hold input samples
reg [DATA_WIDTH-1:0] sample_mem [0:TOTAL_SAMPLES-1];
integer i,data_count;
reg rd_cnt;
// Read file before simulation starts
initial begin
$display("[%0t] Loading sample_data.mem ...", $time);
$readmemh("C:/Users/POOJA SRI/Downloads/sample_data.mem", sample_mem);
$display("[%0t] Loaded %0d samples", $time, TOTAL_SAMPLES);
end

initial begin
resetn=0;
s_valid=0;
s_data=0;
data_count = 0;
#20 resetn=1;

repeat(2) @(posedge clk);

//data_count = 0;

while(data_count < TOTAL_SAMPLES) begin
@(posedge clk);
if (s_ready) begin
s_valid = 1;
s_data  = sample_mem[data_count];
data_count = data_count + 1;
end else begin
s_valid = 0;
$display("[%0t] Finished sending all samples", $time);
end
end
#1000000;
$display("[%0t] Simulation complete", $time);
$finish;
end
endmodule

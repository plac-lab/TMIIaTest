//% @file Format_Data.v
//% @brief This module format a long-bits data into several FIFO_Width datas.
//% @author pyxiong
//% 
//%
`timescale 1ns / 1ps
module Format_Data #(parameter DATA_WIDTH=170, //% Width of parallized input data.
                     parameter VALID_WIDTH=32, //% Width of data_out's valid bits.
                     parameter NUM_WIDTH=4, //% 2**NUM_WIDTH must be greater than DATA_WIDTH/VALID_WIDTH.
                     parameter FIFO_WIDTH=36, //% Width of fifo that data_out sent to
                     parameter NUMBER=DATA_WIDTH/VALID_WIDTH+1, //% quantity of data send to fifo
                     parameter TOTAL_DATA_WIDTH=NUMBER*VALID_WIDTH //% Width of multi factor.
   ) (
   input clk,
   input rst,
   input start,
   input [DATA_WIDTH-1:0] data_in,
   input fifo_full,
   input valid,
   output reg fifo_wr_en,
   output reg [FIFO_WIDTH-1:0] data_out
   );
reg [NUM_WIDTH-1:0] counter;
reg [TOTAL_DATA_WIDTH-1:0] multi;
reg [3:0] current_state, next_state;
parameter s0=4'b0001;
parameter s1=4'b0010;
parameter s2=4'b0100;
parameter s3=4'b1000;

//assign multi = {VALID_WIDTH{1'b1}} << TOTAL_DATA_WIDTH-VALID_WIDTH;
always@(negedge clk or posedge rst)
begin
if(rst)
 begin
 current_state<=s0;
 end
else
 begin
 current_state<=next_state;
 end
end

always@(current_state or rst or valid or counter or start or fifo_full)
begin
 if(rst)
  begin
  next_state=s0;
  end
 else
  begin
   case(current_state)
     s0:next_state=(start==1)?s1:s0;
     s1:next_state=(valid==1&&fifo_full==0)?s2:s1;
     s2:next_state=(fifo_full==1)?s3:
                     (counter==0)?s0:s2;
     s3:next_state=(fifo_full==0)?s2:s3;                
     default:next_state=s0;
    endcase
  end
end

always@(negedge clk or posedge rst)
begin
if(rst)
 begin
 counter <= 0;
 multi <= 0;
 data_out <= 0;
 fifo_wr_en <= 0;
 end
else
 begin
  case(next_state)
   s0:
     begin
     counter <= 0;
     multi <= 0;
     data_out <= 0;
     fifo_wr_en <= 0;
     end
   s1:
     begin
     counter <= NUMBER;
     multi <= {VALID_WIDTH{1'b1}} << TOTAL_DATA_WIDTH-VALID_WIDTH;
     data_out <= 0;
     fifo_wr_en <= 0;
     end
   s2:
     begin
     counter <= counter - 1'b1;    
     data_out <= (data_in & multi)>> (counter-1'b1)*VALID_WIDTH;
     multi <= multi >> VALID_WIDTH;
     fifo_wr_en <= 1;
     end
   s3:
     begin
     counter <= counter;
     multi <= multi;
     data_out <= data_out;
     fifo_wr_en <= 0;
     end
   default:
     begin
     counter <= 0;
     multi <= 0;
     data_out <= 0;
     fifo_wr_en <= 0;
     end
  endcase
 end
end
endmodule

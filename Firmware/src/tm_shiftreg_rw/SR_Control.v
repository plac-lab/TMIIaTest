//% @file SR_Control.v
//% @brief Generate control signals that are sent to shift register.
//% @author pyxiong
//% 
//% when start is asserted, output signals will be sent to 
//% shift register. 
`timescale 1ns / 1ps

module SR_Control #(
    parameter DATA_WIDTH=170, //% @param width of data input
    parameter CNT_WIDTH=8 //% @param width of internal counter
   ) (
    input [DATA_WIDTH-1:0] din, //% 170-bit data input
    input clk, //% control clock
    input rst, //% module reset
    input start, //% start signal
    output reg din_sr, //% data sent to shift register
    output reg load_sr, //% load signal sent to shift register
    output clk_sr //% clock signal sent to shift register
    );
    
reg [4:0] current_state_out, next_state_out;
reg [CNT_WIDTH-1:0] count;
parameter s0=5'b00001;
parameter s1=5'b00010;
parameter s2=5'b00100;
parameter s3=5'b01000;
parameter s4=5'b10000;

assign clk_sr=~rst&&~clk||~rst&&clk&&load_sr;    

//state machine 1, used to send signals to SR
always@(posedge clk or posedge rst)
 begin
  if(rst)
   begin
   current_state_out<=s0;
   end
  else
   begin
   current_state_out<=next_state_out;
   end
 end  
  
always@(current_state_out or rst or start or count)
 begin
  if(rst)
   begin
    next_state_out=s0;
   end
  else
   begin
    case(current_state_out)
     s0:
       begin
        if(start) begin next_state_out=s1; end
        else begin next_state_out=s0; end
       end
     s1: begin next_state_out=s2; end
     s2:
       begin
        if(count==DATA_WIDTH) 
         begin
         next_state_out=s3;
         end
        else
         begin
         next_state_out=s2;
         end
       end
     s3:
       begin
       next_state_out=s4;
       end
     s4:
       begin
       next_state_out=s0;
       end
     default: next_state_out=s0;
    endcase
   end
 end

always@(posedge clk or posedge rst)
begin
 if(rst)
  begin
  count<=0;
  din_sr<=1'b0;
  load_sr<=1'b0;
  end
 else
  begin
   case(next_state_out)
    s0:
      begin
      count<=0;
      din_sr<=1'b0;
      load_sr<=1'b0;
      end
    s1:
      begin
      count<=0;
      din_sr<=1'b0;
      load_sr<=1'b0;
      end
    s2:
      begin
       count<=count+1'b1;
       din_sr<=din[count];
       load_sr<=1'b0;
      end
    s3:
      begin
      count<=0;
      din_sr<=1'b0;
      load_sr<=1'b1;
      end
    s4:
      begin
      count<=0;
      din_sr<=1'b0;
      load_sr<=1'b0;
      end
    default:
      begin
      count<=0;
      din_sr<=1'b0;
      load_sr<=1'b0;
      end
   endcase
  end
end

endmodule

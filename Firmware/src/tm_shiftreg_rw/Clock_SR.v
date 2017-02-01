//% @file Clock_SR.v
//% @brief This module generate shift register's control clock.
//% @author pyxiong
//%
//% After the last bit is written into shift register, clock clk_sr
//% must stop until start is asserted.
`timescale 1ns / 1ps
module Clock_SR #(parameter WIDTH=170,//% @param input data's width controls thestatus of state machine. 
                  parameter CNT_WIDTH=8, //% @param 2**CNT_WIDTH must be greater than WIDTH.
                  parameter DIV_WIDTH=6, //% @param width of division factor
                  parameter COUNT_WIDTH=64 //% @param Width of internal counter, it must be greater than 2**DIV_WIDTH.
    )(
    input clk_in, //% module's internal control clock.
    input rst, //% reset
    input[CNT_WIDTH-1:0] count, //% count from 0 to WIDTH+1, controls the total active duration of clk_sr.  
    input start, //% start signal
    input start_tmp, //% one clk(divided) period behind start signal.
    input [DIV_WIDTH-1:0] div, //% clock frequency division factor 2**div.
    input [COUNT_WIDTH-1:0] counter, //% CLock_Div's internal counter
    output reg clk_sr //% shift register's control clock
    );
//reg [COUNT_WIDTH-1:0] counter;    
reg [1:0] current_state, next_state;
parameter s0 = 2'b01;
parameter s1 = 2'b10;
//parameter s2 = 3'b100;

always@(posedge clk_in or posedge rst)
  begin   
    if(rst)
    begin  current_state <= s0; end
    else
    begin  current_state <= next_state; end    
  end

always@(current_state or rst or count or start or start_tmp)
  begin
    if(rst)
    begin next_state = s0; end
    else
    begin
        case(current_state)
            s0:next_state=(start==0&&start_tmp==1)?s1:s0;
            s1:next_state=(count==WIDTH+1'b1)?s0:s1;
//            s2:next_state=s0;
            default:next_state=s0;
        endcase
    end
  end

always@(posedge clk_in or posedge rst)
begin
  if(rst)
  begin 
  clk_sr<=1;
  end
  else
  begin
    case(next_state)
        s0:
          begin 
          clk_sr<=1; 
          end
        s1:
          begin 
          clk_sr<=~counter[div-1];   
          end
        default:
          begin 
          clk_sr<=1; 
          end
    endcase 
  end 
end

endmodule

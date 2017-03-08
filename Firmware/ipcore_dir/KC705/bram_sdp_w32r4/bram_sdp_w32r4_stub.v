// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.4.2 (lin64) Build 1494164 Fri Feb 26 04:18:54 MST 2016
// Date        : Sun Feb 12 21:45:58 2017
// Host        : FPGALin running 64-bit unknown
// Command     : write_verilog -force -mode synth_stub
//               /home/pyxiong/TMIIaTest/Firmware/ipcore_dir/KC705/bram_sdp_w32r4/bram_sdp_w32r4_stub.v
// Design      : bram_sdp_w32r4
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_3_1,Vivado 2015.4.2" *)
module bram_sdp_w32r4(clka, wea, addra, dina, clkb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[10:0],dina[31:0],clkb,addrb[13:0],doutb[3:0]" */;
  input clka;
  input [0:0]wea;
  input [10:0]addra;
  input [31:0]dina;
  input clkb;
  input [13:0]addrb;
  output [3:0]doutb;
endmodule

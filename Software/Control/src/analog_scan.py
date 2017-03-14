#!/usr/bin/env python
# -*- coding: utf-8 -*-

## @package analog_scan
# This file is used to config topmetal sram and array scan modules.
#
# tm_sram_config() configs the start address of sram and data sent to sram.
# data_to_sram is an array, which contains 45*216 elements, each element is a 4-# bit width data.
# tm_array_scan() controls the topmetal array scan module.  

from command import *
import ctypes
import socket
import time

## topmetal sram config function.
#
# @param[in] s Socket that is already open and connected to the FPGA board.
# @param[in] start_addr address of first data sent to sram.
# @param[in] data sent to sram.
def tm_sram_config(s, start_addr, data_to_sram):
    nval = int((len(data_to_sram)+7)/8)
    addr = start_addr & ((1<<32) -1)
    aval = [0 for i in xrange(nval)]
    for i in xrange(len(data_to_sram)):
        j = i % 8
        k = i / 8
        aval[k] += data_to_sram[i] << (j*4) 
    cmd = Cmd()
    cmdstr = ""
    #write_memory
    cmdstr += cmd.write_memory(addr, aval)
    print [hex(ord(w)) for w in cmdstr]
    
    s.sendall(cmdstr)

## topmetal array scan config function.
#
# @param[in] s Socket that is already open and connected to the FPGA board.
# @param[in] clk_div clock frequency division factor when array is scanning
# @param[in] wr_clk_div clock frequency division factor when writing data into p# ixel.
# @param[in] stop_addr controls where scanning stop.

def tm_array_scan(s, clk_div, wr_clk_div, stop_addr, trig_rate, trig_delay, stop_clk_s, keep_we):
    
    cmd = Cmd()
    cmdstr = ""

    #write_register
    config_reg = ((trig_delay & 0xffff) << 48)|((trig_rate & 0xffff) << 32)|((stop_addr & 0xffff) << 16)|((keep_we & 0x1) << 9)|((stop_clk_s & 0x1) << 8)|((wr_clk_div & 0xf) << 4)|(clk_div & 0xf)
    for i in xrange(4):
        cmdstr += cmd.write_register(i+11, (config_reg >> i*16) & 0xffff)
    
    #send_pulse
    cmdstr += cmd.send_pulse(0x04)

    print [hex(ord(w)) for w in cmdstr]

    s.sendall(cmdstr)



if __name__ == "__main__":
   # host = '192.168.2.3'
   # port = 1024
    host = '127.0.0.1'
    port = 11024
    s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    s.connect((host,port))
    
    #data_to_sram is 45*216 lenth array
    start_addr = 0
    #data_to_sram = [0x5, 0xa, 0x5, 0xa]
    data_to_sram = [i for i in xrange(9719)]
    tm_sram_config(s, start_addr, data_to_sram)

    clk_div    = 7
    wr_clk_div = 14
    stop_addr  = 1 
    trig_rate  = 4
    trig_delay = 1
    stop_clk_s = 0
    keep_we    = 1
    tm_array_scan(s, clk_div, wr_clk_div, stop_addr, trig_rate, trig_delay, stop_clk_s, keep_we)
    
    s.close()

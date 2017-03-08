#!/usr/bin/env python
# -*- coding: utf-8 -*-

## @package sr_ctrl
# This file is used to configure TMIIa  Shift Register module.
#
# data_in is the input data of TMIIa Shift Register module,
# div is division factor of clock frequency(f_out=f_in/2^div),
# trig is start signal of configuration.

from command import *
import socket
import time

## Shift_register write and read function.
#
# @param[in] s Socket that is already open and connected to the FPGA board.
# @param[in] data_to_send 170-bit value to be sent to the external SR.
# @param[in] clk_div Clock frequency division factor: (/2**clk_div).  6-bit wide.
# @return Value stored in the external SR that is read back.
# @return valid signal shows that the value stored in external SR is read back.
def shift_register_rw(s, data_to_send, data_width, clk_div):
    div_reg = (clk_div & 0x3f)
    data_reg = data_to_send & ((1 << data_width)-1)
    n = (data_width + 15)/16

    cmd = Cmd()

    cmdstr = ""
    for i in xrange(n):
        cmdstr += cmd.write_register(0, (data_reg >> i*16) & 0xffff)
        cmdstr += cmd.send_pulse(0x08)
    cmdstr += cmd.write_register(1, div_reg & 0xffff)
    cmdstr += cmd.send_pulse(0x01)

    print [hex(ord(w)) for w in cmdstr]

    s.sendall(cmdstr)

    # read back
    time.sleep(1)
    m = (data_width+31)/32
    g = 4*(1+m)
    cmdstr = ""
    cmdstr += cmd.read_status(0)
    cmdstr += cmd.read_datafifo(m)
    s.sendall(cmdstr)
    retw = s.recv(g)
    print [hex(ord(w)) for w in retw]
    ret_all = 0
    for i in xrange(g):
        ret_all = ret_all | int(ord(retw[i])) << ((g-1-i) * 8 )
    ret = ret_all & ((1 << data_width) - 1)
    valid = (ret_all & (1 << m*32)) >> m*32
    print "%x" % ret
    print valid
    return ret
    return valid

if __name__ == "__main__":
    #host = '192.168.2.3'
    host = "localhost"
    port = 11024
    s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    s.connect((host,port))

    data_in=0x123456
    data_width=170
    div=7
    shift_register_rw(s, data_in, data_width, div)

    s.close()

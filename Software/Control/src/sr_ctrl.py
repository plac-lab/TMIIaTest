#!/usr/bin/env python

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
def shift_register_rw(s, data_to_send, clk_div):
    div_reg = (clk_div & 0x3f) << 170
    data_reg = data_to_send & 0x3ffffffffffffffffffffffffffffffffffffffff

    cmd = Cmd()

    val = div_reg | data_reg
    cmdstr = ""
    for i in xrange(11):
        cmdstr += cmd.write_register(i, (val >> i*16) & 0xffff)

    cmdstr += cmd.send_pulse(0x01)

    print [hex(ord(w)) for w in cmdstr]

    s.sendall(cmdstr)

    # read back
    ret = 0
    # s.recv()
    return ret

if __name__ == "__main__":
    host = '192.168.2.3'
    host = '127.0.0.1'
    port = 2024
    s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    s.connect((host,port))

    data_in=123456
    div=12
    shift_register_rw(s, data_in, div)

    s.close()


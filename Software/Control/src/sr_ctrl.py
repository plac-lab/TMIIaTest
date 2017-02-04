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
def shift_register_rw(s, data_to_send, clk_div):
    div_reg = (clk_div & 0x3f) << 170
    data_reg = data_to_send & ((1<<170)-1)

    cmd = Cmd()

    val = div_reg | data_reg
    cmdstr = ""
    for i in xrange(11):
        cmdstr += cmd.write_register(i, (val >> i*16) & 0xffff)

    cmdstr += cmd.send_pulse(0x01)

    print [hex(ord(w)) for w in cmdstr]

    s.sendall(cmdstr)

    # read back
    time.sleep(1)
    cmdstr = ""
    for i in xrange(11):
        cmdstr += cmd.read_status(10-i)
    s.sendall(cmdstr)
    retw = s.recv(4*11)
    print [hex(ord(w)) for w in retw]
    ret_all = 0
    for i in xrange(11):
        ret_all = ret_all | int(ord(retw[i*4+2])) << ((10-i) * 16 + 8) | int(ord(retw[i*4+3])) << ((10-i) * 16)
    ret = ret_all & ((1<<170)-1)
    valid = (ret_all & (1 <<170)) >> 170
    print "%x" % ret
    print valid
    return ret
    return valid

if __name__ == "__main__":
    host = '192.168.2.3'
    port = 1024
    s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    s.connect((host,port))

    data_in=123456
    div=7
    shift_register_rw(s, data_in, div)

    s.close()

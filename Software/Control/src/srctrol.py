## @package srctrol.py
# This file is used to configure TMIIa  Shift Register module.
#
# data_in is the input data of TMIIa Shift Register module,
# div is division factor of clock frequency(f_out=f_in/2^div),
# trig is start signal of configuration.

#!/usr/bin/env python
from command import *
import socket
import time

## Shift_register write and read function,
#
# This function has three inputs: data_in,div,trig,
# one output: data_out
# data_in: 170 bits, div: 6 bits, trig: 1 bit.
def shift_register_rw(data_in, div, trig, data_out):
    div_reg = (div & 0x3f) << 170
    data_reg = data_in & 0x3ffffffffffffffffffffffffffffffffffffffff
    host = '192.168.2.3'
    port = 1024
    s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    s.connect((host,port))

    cmd = Cmd()

    val = div_reg + data_reg
    cmdstr = ""
    for i in xrange(11):
        cmdstr += cmd.write_register(i, (val >> i*16) & 0xffff)

    cmdstr += cmd.send_pulse(trig & 0x01)

    print [hex(ord(w)) for w in cmdstr]

    s.sendall(cmdstr)

if __name__ == "__main__":
    data_in=123456
    div=12
    trig=1
    shift_register_rw(data_in,div,trig,0)



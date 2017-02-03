#!/usr/bin/env python
# -*- coding: utf-8 -*-

## @package TMS1mmSingle
# Control module for the Topmetal-S 1mm Electrode single-chip test.
#

import copy
from command import *
import socket
import time

## Manage Topmetal-S 1mm chip's internal register map.
# Allow combining and disassembling individual registers
# to/from long integer for I/O
#
class TMS1mmReg:
    ## @var _defaultRegMap default register values
    _defaultRegMap = {
        'DAC'    : [0x75c3, 0x8444, 0x7bbb, 0x7375, 0x86d4, 0xe4b2], # from DAC1 to DAC6
        'PD'     : [1, 1, 1, 1], # from PD1 to PD4, 1 means powered down
        'K'      : [1, 0, 1, 0, 1, 0, 0, 0, 0, 0], # from K1 to K10, 1 means closed (conducting)
        'vref'   : 0x4,
        'vcasp'  : 0x4,
        'vcasn'  : 0x4,
        'vbiasp' : 0x4,
        'vbiasn' : 0x4
    }
    ## @var register map local to the class
    _regMap = {}

    def __init__(self):
        self._regMap = copy.deepcopy(self._defaultRegMap)

    def set_dac(self, i, val):
        self._regMap['DAC'][i] = 0xffff & val

    def set_power_down(self, i, onoff):
        self._regMap['PD'][i] = 0x1 & onoff

    def set_k(self, i, onoff):
        self._regMap['K'][i] = 0x1 & onoff

    def set_vref(self, val):
        self._regMap['vref'] = val & 0xf

    def set_vcasp(self, val):
        self._regMap['vcasp'] = val & 0xf

    def set_vcasn(self, val):
        self._regMap['vcasn'] = val & 0xf

    def set_vbiasp(self, val):
        self._regMap['vbiasp'] = val & 0xf

    def set_vbiasn(self, val):
        self._regMap['vbiasn'] = val & 0xf

    ## Get long-integer variable
    def get_config_vector(self):
        ret = ( self._regMap['vbiasn'] << 126 |
                self._regMap['vbiasp'] << 122 |
                self._regMap['vcasn']  << 118 |
                self._regMap['vcasp']  << 114 |
                self._regMap['vref']   << 110 )
        for i in xrange(len(self._regMap['K'])):
            ret |= self._regMap['K'][i] << (len(self._regMap['K']) - i) + 99
        for i in xrange(len(self._regMap['PD'])):
            ret |= self._regMap['PD'][i] << (len(self._regMap['PD']) - i) + 95
        for i in xrange(len(self._regMap['DAC'])):
            ret |= self._regMap['DAC'][i] << (len(self._regMap['DAC'])-1 - i)*16
        return ret

    dac_fit_a = 4.35861E-5
    dac_fit_b = 0.0349427
    def dac_volt2code(self, v):

        c = int((v - self.dac_fit_b) / self.dac_fit_a)
        if c < 0:     c = 0
        if c > 65535: c = 65535
        return c

    def dac_code2volt(self, c):
        v = c * self.dac_fit_a + self.dac_fit_b
        return v

## Command generator for controlling DAC8568
#
class DAC8568:
 
    def __init__(self, cmd):
        self.cmd = cmd
    def DACVolt(self, x):
        return int(x / 2.5 * 65536.0)    #calculation
    def write_spi(self, val):
        ret = ""          # 32 bits 
        ret += self.cmd.write_register(0, (val >> 16) & 0xffff)
        ret += self.cmd.send_pulse(2)
        ret += self.cmd.write_register(0, val & 0xffff)
        ret += self.cmd.send_pulse(2)
        return ret
    def turn_on_2V5_ref(self):
        return self.write_spi(0x08000001)
    def set_voltage(self, ch, v):
        return self.write_spi((0x03 << 24) | (ch << 20) | (self.DACVolt(v) << 4))
 
## Shift_register write and read function.
#
# @param[in] s Socket that is already open and connected to the FPGA board.
# @param[in] data_to_send 130-bit value to be sent to the external SR.
# @param[in] clk_div Clock frequency division factor: (/2**clk_div).  6-bit wide.
# @return Value stored in the external SR that is read back.
# @return valid signal shows that the value stored in external SR is read back.
def shift_register_rw(s, data_to_send, clk_div):
    div_reg = (clk_div & 0x3f) << 130
    data_reg = data_to_send & 0x3ffffffffffffffffffffffffffffffff

    cmd = Cmd()

    val = div_reg | data_reg
    cmdstr = ""
    for i in xrange(9):
        cmdstr += cmd.write_register(i, (val >> i*16) & 0xffff)

    cmdstr += cmd.send_pulse(0x01)

#    print [hex(ord(w)) for w in cmdstr]

    s.sendall(cmdstr)

    time.sleep(0.5)

    # read back
    cmdstr = ""
    for i in xrange(9):
        cmdstr += cmd.read_status(8-i)
    s.sendall(cmdstr)
    retw = s.recv(4*9)
#    print [hex(ord(w)) for w in retw]
    ret_all = 0
    for i in xrange(9):
        ret_all = ret_all | ( int(ord(retw[i*4+2])) << ((8-i) * 16 + 8) |
                              int(ord(retw[i*4+3])) << ((8-i) * 16))
    ret = ret_all & 0x3ffffffffffffffffffffffffffffffff
    valid = (ret_all & (1 << 130)) >> 130
    print "Return: 0x%0x, valid: %d" % (ret, valid)
    return ret

if __name__ == "__main__":

    host = '192.168.2.3'
    port = 1024
    s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    s.connect((host,port))

    cmd = Cmd()
    dac8568 = DAC8568(cmd)
    s.sendall(dac8568.turn_on_2V5_ref())
    s.sendall(dac8568.set_voltage(6, 1.2))

    x2gain = 2
    bufferTest = True
    tms1mmReg = TMS1mmReg()
    tms1mmReg.set_power_down(0, 0)
    tms1mmReg.set_power_down(3, 0)

    if bufferTest:
        tms1mmReg.set_k(0, 0) # 0 - K1 is open, disconnect CSA output
        tms1mmReg.set_k(1, 1) # 1 - K2 is closed, allow BufferX2_testIN to inject signal
        tms1mmReg.set_k(4, 0) # 0 - K5 is open, disconnect SDM loads
        tms1mmReg.set_k(6, 1) # 1 - K7 is closed, BufferX2 output to AOUT_BufferX2
    if x2gain == 2:
        tms1mmReg.set_k(2, 1) # 1 - K3 is closed, K4 is open, setting gain to X2
        tms1mmReg.set_k(3, 0)
    else:
        tms1mmReg.set_k(2, 0)
        tms1mmReg.set_k(3, 1)

    tms1mmReg.set_k(6, 1) # 1 - K7 is closed, BufferX2 output to AOUT_BufferX2
    tms1mmReg.set_k(7, 1) # 1 - K8 is closed, connect CSA out to AOUT1_CSA
    tms1mmReg.set_dac(0, tms1mmReg.dac_volt2code(1.38)) # VBIASN R45
    tms1mmReg.set_dac(1, tms1mmReg.dac_volt2code(1.55)) # VBIASP R47
    tms1mmReg.set_dac(2, tms1mmReg.dac_volt2code(1.45)) # VCASN  R29
    tms1mmReg.set_dac(3, tms1mmReg.dac_volt2code(1.35)) # VCASP  R27
    # tms1mmReg.set_dac(4, dac_volt2code(1.58)) # VDIS   R16, use external DAC
    s.sendall(dac8568.set_voltage(4, 1.58))
    tms1mmReg.set_dac(5, tms1mmReg.dac_volt2code(2.68)) # VREF   R14

    data_to_send = tms1mmReg.get_config_vector()
    print "Sent: 0x%0x" % (data_to_send)

    div=7
    shift_register_rw(s, (data_to_send), div)

    s.close()

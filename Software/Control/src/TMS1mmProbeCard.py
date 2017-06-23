#!/usr/bin/env python
# -*- coding: utf-8 -*-

## @package TMS1mmProbeCard
# Control module for the Topmetal-S 1mm Electrode probe card.
#

from __future__ import print_function
import copy
from command import *
import socket
import time
import sys
import argparse

## Manage Topmetal-S 1mm chip's internal register map.
# Allow combining and disassembling individual registers
# to/from long integer for I/O
#
class TMS1mmReg(object):
    ## @var _defaultRegMap default register values
    _defaultRegMap = {
        'DAC'    : [0x75c3, 0x8444, 0x7bbb, 0x7375, 0x86d4, 0xe4b2], # from DAC1 to DAC6
        'PD'     : [1, 1, 1, 1], # from PD1 to PD4, 1 means powered down
        'K'      : [1, 0, 1, 0, 1, 0, 0, 0, 0, 0], # from K1 to K10, 1 means closed (conducting)
        'vref'   : 0x8,
        'vcasp'  : 0x8,
        'vcasn'  : 0x8,
        'vbiasp' : 0x8,
        'vbiasn' : 0x8
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
class DAC8568(object):
 
    def __init__(self, cmd, pulseId=1):
        self._pulseId = pulseId
        self.cmd = cmd
    def DACVolt(self, x):
        return int(x / 2.5 * 65536.0)    #calculation
    def write_spi(self, val):
        ret = ""          # 32 bits 
        ret += self.cmd.write_register(0, (val >> 16) & 0xffff)
        ret += self.cmd.send_pulse(1<<self._pulseId)
        ret += self.cmd.write_register(0, val & 0xffff)
        ret += self.cmd.send_pulse(1<<self._pulseId)
        return ret
    def turn_on_2V5_ref(self):
        return self.write_spi(0x08000001)
    def set_voltage(self, ch, v):
        return self.write_spi((0x03 << 24) | (ch << 20) | (self.DACVolt(v) << 4))

## Command generator for controlling ADS124S0X
#
class ADS124S0X(object):

    def __init__(self, cmd, pulseId=2, configRegId=0, statusRegId0=9, acqDelay=0.2):
        self._pulseId = pulseId
        self._configRegId = configRegId
        self._statusRegId0 = 9
        # time to wait for ADC to finish a sample
        self.acqDelay = acqDelay
        self.cmd = cmd

    def write_spi(self, val):
        ret = "" # 32 bits
        ret += self.cmd.write_register(self._configRegId, (val >> 16) & 0xffff)
        ret += self.cmd.send_pulse(1<<self._pulseId)
        ret += self.cmd.write_register(self._configRegId, val & 0xffff)
        ret += self.cmd.send_pulse(1<<self._pulseId)
        return ret

    def read_reg(self, addr, n=2):
        rreg = (1<<5) | (0x1f & addr)
        if n == 0: n = 1
        nreg = 0x1f & (n-1)
        val = (rreg << 24) | (nreg << 16)
        return self.write_spi(val)

    def write_reg(self, addr, d1, d2=0, n=1):
        wreg = (1<<6) | (0x1f & addr)
        if n == 0: n = 1
        if n > 2 : n = 2
        nreg = 0x1f & (n-1)
        val = (wreg << 24) | (nreg << 16) | d1 << 8 | d2
        return self.write_spi(val)

    def initialize(self):
        cmdstr  = ""
        cmdstr += self.write_reg(0x04, 0x14, # Low-latency filter, 20SPS
                                       0x3a, # Internal 2.5V reference
                                 n=2)
        cmdstr += self.write_spi(0x08<<24) # START
        return cmdstr

    def select_channel(self, ch):
        cmdstr = ""
        if ch == -1: # temperature sensor or internal check sources
            cmdstr += self.write_reg(0x09, 0x50) # SYS_MON, temperature, 129mV @25C
            #cmdstr += self.write_reg(0x09, 0x90) # SYS_MON, DVDD/4.0
            #cmdstr += self.write_reg(0x09, 0x70) # SYS_MON, (AVDD-AVSS)/4.0
            cmdstr += self.write_reg(0x03, 0x08) # PGA_EN, GAIN 1
        else:
            cmdstr += self.write_reg(0x09, 0x10) # SYS_MON, disable
            cmdstr += self.write_reg(0x03, 0x00) # PGA_EN, PGA disabled.
            cmdstr += self.write_reg(0x02, ((0x0f & ch)<<4) | 0x0c) # tie MUXP=AIN[ch], MUXN=AINCOM
        return cmdstr

    def restart(self):
        cmdstr = self.write_spi(0x0a<<24) # STOP
        cmdstr += self.write_spi(0x08<<24) # START
        return cmdstr

    ## Methods start with recv_ will take an open socket s and actually perform communication.
    # Read captured din from status_reg
    #
    def recv_din(self, s, n16=2, delay=0.001):
        cmdstr = ""
        for i in xrange(n16):
            cmdstr += self.cmd.read_status(self._statusRegId0+i)
        time.sleep(delay) # wait for status_reg to be ready
        s.sendall(cmdstr)
        retw = s.recv(4*n16)
        ret = 0
        for i in xrange(n16):
            ret |= (ord(retw[i*4+2]) << (i*16 + 8)) | (ord(retw[i*4+3]) << i*16)
        return ret

    def recv_data(self, s):
        rdata = 0x12
        val = rdata << 24
        s.sendall(self.write_spi(val))
        return self.recv_din(s)

    ## Convert received adc data to voltage
    #
    def adcvolt(self, data, vn=0.0, gain=1, vref=2.5, mode="single"):
        adccode = 0xffffff & data
        sign = adccode >> 23
        if sign == 0:
            adcint = adccode
        else: # negative, 2's complement
            adcint = adccode - (1<<24)
        if mode == "single":
            gain = gain * 0.5
        volt = adcint * vref / (1<<24) / gain + vn
        return volt

    ## Convert received adc data to internal sensor temperature
    #
    def adctemp(self, data):
        v = self.adcvolt(data)
        c = 25.0 + (v - 0.129) / 0.000403
        return c

## Class for controlling Keithley 2450 SMU
#
class SMU2450(object):

    def __init__(self, ipaddr="192.168.2.100", ipport=5025):
        self._ipaddr = ipaddr
        self._ipport = ipport

    def volt_on(self, v=7.0, iLimit=0.2):
        s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
        s.connect((self._ipaddr, self._ipport))
        s.sendall(":ABORT\n:TRIG:LOAD \"EMPTY\"\n")
        s.sendall(":SENS:FUNC \"CURR:DC\"\n:SENS:CURR:RANG:AUTO ON\n:SENS:CURR:RSEN OFF\n")
        s.sendall(":SOUR:FUNC VOLT\n:SOUR:VOLT {0:f}\n:SOUR:VOLT:ILIM {1:f}\n".format(v, iLimit))
        s.sendall(":OUTP ON\n:TRIG:LOAD \"LoopUntilEvent\", COMM, 100\n:INIT\n")
        s.close()
    def volt_off(self):
        s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
        s.connect((self._ipaddr, self._ipport))
        s.sendall(":ABORT\n:TRIG:LOAD \"EMPTY\"\n")
        s.sendall(":OUTP OFF\n:TRIG:LOAD \"LoopUntilEvent\", COMM, 100\n:INIT\n")
        s.close()

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

#    print([hex(ord(w)) for w in cmdstr])

    s.sendall(cmdstr)

    time.sleep(0.2)

    # read back
    cmdstr = ""
    for i in xrange(9):
        cmdstr += cmd.read_status(8-i)
    s.sendall(cmdstr)
    retw = s.recv(4*9)
#    print([hex(ord(w)) for w in retw])
    ret_all = 0
    for i in xrange(9):
        ret_all = ret_all | ( int(ord(retw[i*4+2])) << ((8-i) * 16 + 8) |
                              int(ord(retw[i*4+3])) << ((8-i) * 16))
    ret = ret_all & 0x3ffffffffffffffffffffffffffffffff
    valid = (ret_all & (1 << 130)) >> 130
    print("Return: 0x%0x, valid: %d" % (ret, valid))
    return ret

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("-m", "--smu-ip-port", type=str, default="192.168.2.100:5025", help="SMU 2450 ipaddr and port")
    parser.add_argument("-c", "--control-ip-port", type=str, default="192.168.2.3:1024", help="main control system ipaddr and port")
    parser.add_argument("-l", "--code-lower", type=int, default=0, help="Code scan lower limit")
    parser.add_argument("-u", "--code-upper", type=int, default=58000, help="Code scan upper limit")
    parser.add_argument("-s", "--code-step", type=int, default=2000, help="Code scan step size")
    parser.add_argument("-p", "--prefix", type=str, default="data/", help="Data file prefix, can be used to put files under directories")
    parser.add_argument("x", type=int, default=0, help="Chip location x")
    parser.add_argument("y", type=int, default=0, help="Chip location y")

    args = parser.parse_args()

    datafname = args.prefix + "x{0:04d}y{1:04d}.dat".format(args.x, args.y)
    print("Writing data to {0:s}".format(datafname))
    fp = open(datafname, "a+")
    fp.write("\n\n# Chip {0:d} {1:d}\n".format(args.x, args.y))

    smuipport = args.smu_ip_port.split(':')
    smu = SMU2450(smuipport[0], int(smuipport[1]))
    smu.volt_on()
    time.sleep(2)
#    smu.volt_off()

    ctrlipport = args.control_ip_port.split(':')
    s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    s.connect((ctrlipport[0],int(ctrlipport[1])))

    cmd = Cmd()
    dac8568 = DAC8568(cmd)
    s.sendall(dac8568.turn_on_2V5_ref())
    s.sendall(dac8568.set_voltage(6, 1.2))

    # enable SDM clock
#    s.sendall(cmd.write_register(9, 0x01))

    x2gain = 2
    bufferTest = True
    sdmTest = True

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
    if sdmTest:
        tms1mmReg.set_k(4, 0)
        tms1mmReg.set_k(5, 1)
    else:
        tms1mmReg.set_k(5, 0)

    for dacCode in xrange(args.code_lower, args.code_upper+1, args.code_step):
        fp.write("{0:6d} ".format(dacCode))

        tms1mmReg.set_k(6, 1) # 1 - K7 is closed, BufferX2 output to AOUT_BufferX2
        tms1mmReg.set_k(7, 1) # 1 - K8 is closed, connect CSA out to AOUT1_CSA
        tms1mmReg.set_dac(0, dacCode) # VBIASN R45
        tms1mmReg.set_dac(1, dacCode) # VBIASP R47
        tms1mmReg.set_dac(2, dacCode) # VCASN  R29
        tms1mmReg.set_dac(3, dacCode) # VCASP  R27
        tms1mmReg.set_dac(4, dacCode) # VDIS   R16, use external DAC
        tms1mmReg.set_dac(5, dacCode) # VREF   R14

        data_to_send = tms1mmReg.get_config_vector()
        print("Sent:   0x{0:0x}".format(data_to_send))

        div=7
        # write/read twice for validation
        shift_register_rw(s, (data_to_send), div)
        ret = shift_register_rw(s, (data_to_send), div)
        if data_to_send == ret:
            print("Read-back successful.")
        else:
            print("Read-back failed!")

        adc = ADS124S0X(cmd)
        # reset
        s.sendall(adc.write_spi(0x06<<24))
        time.sleep(0.005) # > 4096*(tCLK = 4.096MHz)
        # initialize
        s.sendall(adc.initialize())
        # get data
        for ch in xrange(-1, 7):
            # select channel
            s.sendall(adc.select_channel(ch))
            time.sleep(adc.acqDelay)
            # read reg
            ret = adc.read_reg(0x02)
            s.sendall(ret)
            val = adc.recv_din(s)
            print("ch={0:2d} 0x{1:08x}".format(ch, val))
            # RDATA
            val = adc.recv_data(s)
            c = "{0:7.3f}C".format(adc.adctemp(val)) if ch == -1 else ""
            print("0x{0:08x} {1:d} {2:12.9f}V {3}".format(val, val&0xffffff, adc.adcvolt(val), c))
            fp.write(" {0:12.9f}".format(adc.adcvolt(val)))
        fp.write("\n")
        fp.flush()

    s.close()
    smu.volt_off()
    fp.close()

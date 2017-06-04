#!/usr/bin/env python

## @package dac_scan
# Scan DAC input code and measure output voltage using HP34401A
#

from __future__ import print_function
import copy
import socket
import time
import sys
import serial
from command import *
from TMS1mmSingle import *

## HP34401A multimeter control
class HP34401A(object):

    ## Initialization
    # @param s An already open serial object to talk to the device.
    def __init__(self, s):
        self._s = s
        # Enter remote mode.  RS-232 requires it.
        self._s.write("SYSTem:REMote\n")
        time.sleep(1)

    ## @var numTaken number of data points taken
    _numTaken = 0

    ## @var numMax maximum number of data points allowed by the instrument
    _numMax = 512
    
    def identify(self):
        self._s.write("*IDN?\n")
        ret = self._s.readline()
        return ret[:-1]

    def setup_measurement(self):
        self._s.write("*RST\n") # reset
        time.sleep(1)
        self._s.write("SYST:BEEP:STAT OFF\n") # turn off beeper
        self._s.write("CONF:VOLT:DC 10, 1E-5\n") # range, resolution
        self._s.write("VOLT:DC:NPLC 10\n") # Integration time in # of power line cycles
        self._s.write("INP:IMP:AUTO ON\n") # input impedance.  ON: >10G for 0.1,1,10V range, OFF: 10M
        self._s.write("SENS:ZERO:AUTO ON\n") # auto zero. options are ON|OFF|ONCE
        # self._s.write("VOLT:DC:RANG?; :VOLT:DC:RES?; :VOLT:DC:NPLC?\n")
        # ret = self._s.readline()[:-1]
        # return "Range;Resolution;NPLC: " + ret

    def set_trigger_then_arm(self):
        self._s.write("*CLS\n") # clear status
        self._s.write("TRIG:SOUR BUS\n") # options are BUS|IMM|EXT
        self._s.write("TRIG:DEL:AUTO ON\n") # automatic trigger delay
        self._s.write("TRIG:COUN %d\n" % self._numMax) # number of triggers the instrument will accept before returning to idle
        self._s.write("SAMP:COUN 1\n") # 1 sample per trigger (up to 50000 allowed, but memory can only store 512)
        # self._s.write("READ?\n") # enter wait-for-trigger state
        self._s.write("INIT\n") # enter wait-for-trigger state
        self._numTaken = 0

    def measure_one_point(self):
        if self._numTaken < self._numMax:
            self._s.write("*TRG\n")
            self._numTaken += 1
        else:
            print("Maximum number of data points %d reached\n" % self._numMax)

    def get_points_taken(self):
        time.sleep(1)
        self._s.write("DATA:POIN?\n")
        ret = self._s.readline()
        return int(ret)

    def get_data(self):
        self._s.write("FETC?\n")
        ret = self._s.readline()
        return [float(x) for x in ret[:-2].split(',')]

if __name__ == "__main__":

    ser = serial.Serial('/dev/tty.usbserial-FT0CWADV',
                        9600, 8, serial.PARITY_NONE, serial.STOPBITS_TWO,
                        timeout=10)
    print(ser)
    dmm = HP34401A(ser)
    print(dmm.identify())
    print(dmm.setup_measurement())

    host = '192.168.2.3'
    port = 1024
    sock = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    sock.connect((host,port))

    x2gain = 1
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
    tms1mmReg.set_dac(0, 0x0000) # VBIASN
    tms1mmReg.set_dac(1, 0xffff) # VBIASP

    div = 7 # SR clock freq divisor 2**div
    stepsize = 1 # DAC code step size
    batches = 128 # total # of points taken is 512 * batches

    dfp = open("dacscan.dat", "w")
    dfp.write("# step size %d\n" % stepsize)

    for i in xrange(batches):
        dmm.set_trigger_then_arm()
        for j in xrange(dmm._numMax):
            dacVal = (i*dmm._numMax + j) * stepsize
            print("sample id = %d, dacVal = %d, 0x%04x" % (j, dacVal, dacVal))
            tms1mmReg.set_dac(2, dacVal)
            data_to_send = tms1mmReg.get_config_vector()
            print("Sent to SR: 0x%0x" % (data_to_send))
            shift_register_rw(sock, (data_to_send), div)
            dmm.measure_one_point()
        dmm.get_points_taken()
        dmmData = dmm.get_data()
        j = 0
        for x in dmmData:
            dfp.write("%6d %24.16E\n" % ((i*dmm._numMax + j) * stepsize, x))
            j += 1
        dfp.flush()

    dfp.close()

    sock.close()
    ser.close()
